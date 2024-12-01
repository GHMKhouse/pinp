
import std/[json,lenientops,math,os,tables,streams,strutils]
import easings,optimizer,tools,types
const
  dt=0.016
  epsilon=1e-6
template time2B(x:JsonNode):float=
  x[0].num.float+x[1].num/x[2].num
iterator iterSlice[T](x:seq[T],s:Slice[int]): T=
  for i in s:
    yield x[i]
iterator xrange(a,b,s:float32):float32=
  for i in int(a/s)..int(b/s):
    yield i.toFloat*s
proc B2S*(x:float,bpmList:seq[JsonNode]):float=
  var
    lastBPM=bpmList[0]
  if bpmList.len==1 or x<time2B(lastBPM["startTime"]):
    return (x/lastBPM["bpm"].getFloat*60)
  for bpm in bpmList.iterSlice(1..<bpmList.len):
    if time2B(bpm["startTime"])>x:
      result += ((x-time2B(lastbpm["startTime"]))/lastBPM["bpm"].getFloat*60)
      return
    else:
      result += ((time2B(bpm["startTime"])-time2B(lastbpm["startTime"]))/lastBPM["bpm"].getFloat*60)
      lastBPM=bpm
  return 
proc getSongLength(j:JsonNode):float32=
  if "duration" in j["META"]:
    result=j["META"]["duration"].getFloat()
  else:
    for l in j["judgeLineList"]:
      if "notes" in l:
        for n in l["notes"]:
          result=max(result,B2S(n["endTime"].time2B(),j["BPMList"].getElems()))
      for la in l["eventLayers"]:
        if la.kind==JNull:continue
        for e in ["alphaEvents","moveXEvents","moveYEvents","rotateEvents"]:
          if e in la:
            result=max(result,B2S(la[e][^1]["endTime"].time2B(),j["BPMList"].getElems()))
  j["songLength"]=newJFloat(result)
proc calcL(events:seq[(float32,float32,float64,float64)],t:float32):float64=
  var (_,_,_,lv)=events[0]
  for i,e in events.pairs:
    let (t1,t2,v1,v2)=e
    if t<t1:
      result+=lv
      break
    elif t<t2:
      result+=v1+(v2-v1)*(t-t1)/(t2-t1)
      break
    lv=v2
proc nextT(layers:Layers,t:int32):int32=
  result=int32.high
  for layer in layers.top.getElems:
    block cyc:
      if layer.kind!=JObject:break cyc
      if layers.kind in layer:
        var i=layer[layers.kind&"I"].getInt
        if i>=layer[layers.kind].elems.len:
          break cyc
        while t>=int(layer[layers.kind][i]["endTimeS"].getFloat*1000):
          inc layer[layers.kind&"I"].num
          inc i
          if i>=layer[layers.kind].elems.len:
            break cyc
        if t<int(layer[layers.kind][i]["startTimeS"].getFloat*1000):
          result=min(result,int(layer[layers.kind][i]["startTimeS"].getFloat*1000))
        elif t<int(layer[layers.kind][i]["endTimeS"].getFloat*1000):
          result=min(result,int(layer[layers.kind][i]["endTimeS"].getFloat*1000))
        else:
          raiseAssert "?"

proc calc(layers:Layers,t:float32):float32=
  result=0.0
  for layer in layers.top.getElems:
    if layer.kind==JNull:continue
    if layers.kind in layer:
      for i in max(0,layer[layers.kind&"I"].getInt-10)..<layer[layers.kind].len:
        layer[layers.kind&"I"].num=i
        let e=layer[layers.kind][i]
        let
          t1=e["startTimeS"].getFloat
          t2=e["endTimeS"].getFloat
          v1=e["start"].getFloat
          v2=e["end"].getFloat
          e1=e["easingLeft"].getFloat(0.0)
          e2=e["easingRight"].getFloat(1.0)
        if t<t1:
          result+=(if i==0:v1 else:layer[layers.kind][i-1]["end"].getFloat)
          break
        elif t<t2:
          result+=v1+(v2-v1)*easings[Easing(e["easingType"].getInt)]((t-t1)/(t2-t1)*(e2-e1)+e1)
          break
        elif i==layer[layers.kind].getElems.len-1:
          result+=v2
iterator tran(j:JsonNode,li:int,kind:string):(float32,float32,float32,float32)=
  var l=j["judgeLineList"][li]
  var
    la=l["eventLayers"].toLayers(kind)
    lt:int32=int32(l["eventLayers"][0][kind][0]["startTimeS"].getFloat*1000)
    lv:float32=calc(la,lt/1000)
  l["eventLayers"][0][kind&"I"]=newJInt(0)
  yield (-99999.99'f32,lt/1000,lv,lv)
  if l["father"].getInt==(-1):
    var t:int32=lt
    while true:
      t=nextT(la,t)
      if t==int32.high:break
      let
        v=calc(la,t/1000)
      if abs(v-lv)<=0.1 or abs(t-lt)<=16:
        yield (lt/1000,t/1000,lv,v)
      else:
        for ttt in (lt shr 4)..(t shr 4):
          let tt=ttt shl 4
          var
            tv=calc(la,tt/1000)
          if tt>lt:
            yield (lt/1000,tt/1000,lv,tv)
            lt=tt
            lv=tv
        yield (lt/1000,t/1000,lv,v)
      lt=t
      lv=v
proc tran*(j:JsonNode,s:var FileStream)=
  s.write uint32(0)
  s.write float32(-j["META"]["offset"].getFloat/1000)
  s.write j.getSongLength()
  s.write uint32(0)
  template begin(name:string)=
    s.write uint32.high
    s.write name.alignLeft(12)
    # echo name
  for i,l in j["judgeLineList"].getElems.pairs:
    begin("MOVEX")
    for e in tran(j,i,"moveXEvents"):
      let (t1,t2,v1,v2)=e
      s.write t1
      s.write t2
      s.write v1/1350
      s.write v2/1350
    begin("MOVEY")
    for e in tran(j,i,"moveYEvents"):
      let (t1,t2,v1,v2)=e
      s.write t1
      s.write t2
      s.write v1/900
      s.write v2/900
    begin("ROTATE")
    for e in tran(j,i,"rotateEvents"):
      let (t1,t2,v1,v2)=e
      s.write t1
      s.write t2
      s.write -v1
      s.write -v2
    begin("ALPHA")
    for e in tran(j,i,"alphaEvents"):
      let (t1,t2,v1,v2)=e
      s.write t1
      s.write t2
      s.write v1/255
      s.write v2/255
    begin("FLOOR")
    var floorEvents:seq[(float32,float32,float64,float64)]
    var
      floor:float64=0.0
      lt:float32=(-99999.9)
      ls:float32=10.0
    template addFloorEvent(t1,t2:float32,f1,f2:float64)=
      s.write t1
      s.write t2
      s.write f1*1.2'f64
      s.write f2*1.2'f64
      s.write uint64(0)                                   # reserved
      floorEvents.add (t1,t2,f1*1.2'f64,f2*1.2'f64)
    for e in l["eventLayers"][0]["speedEvents"]:
      let lf=floor
      floor+=(e["startTimeS"].getFloat-lt)*ls
      addFloorEvent(lt,e["startTimeS"].getFloat.float32,lf,floor)
      if abs(e["start"].getFloat-e["end"].getFloat)<0.00001:
        let t1=float32(e["startTimeS"].getFloat)
        let t2=float32(e["endTimeS"].getFloat)
        let f1=(floor)
        floor+=(t2-t1)*e["start"].getFloat
        let f2=(floor)
        addFloorEvent(t1,t2,f1,f2)
        lt=t2
        ls=e["end"].getFloat
      else:
        var t=0.0
        while t+e["startTimeS"].getFloat<e["endTimeS"].getFloat-dt/4:
          let
            t1=t
            t2=t+dt
            f1=(floor)
          floor+=dt*(
            e["start"].getFloat+(e["end"].getFloat-e["start"].getFloat)*(t+dt/2)/(e["endTimeS"].getFloat-e["startTimeS"].getFloat)
            )
          doAssert floor!=f1,$(dt*(
            e["start"].getFloat+(e["end"].getFloat-e["start"].getFloat)*(t+dt/2)/(e["endTimeS"].getFloat-e["startTimeS"].getFloat)
            ))
          addFloorEvent((t1+e["startTimeS"].getFloat).float32,(t2+e["startTimeS"].getFloat).float32,f1,floor)
          t+=dt
        lt=e["endTimeS"].getFloat
        ls=e["end"].getFloat
    let lf=floor
    floor+=(j["songLength"].getFloat+9999.99-lt)*ls
    addFloorEvent(lt,j["songLength"].getFloat.float32+9999.99'f32,lf.float32,floor.float32)
    begin("NOTES")
    if "notes" in l:
      for e in l["notes"]:
        s.write float32(e["startTimeS"].getFloat)
        s.write float32(e["endTimeS"].getFloat)
        s.write float32(e["positionX"].getFloat/450)
        s.write float32(e["speed"].getFloat)
        s.write uint32((case e["type"].getInt
        of 1:0
        of 2:2
        of 3:3
        of 4:1
        else:0) or ((1-e["above"].getInt) shl 2) or ((1-e["isFake"].getInt)shl 3) or (e["hl"].getInt shl 4))
        s.write uint32(0)
        s.write uint64(0)
        s.write float64(calcL(floorEvents,e["startTimeS"].getFloat))
        s.write float64(calcL(floorEvents,e["endTimeS"].getFloat))
    begin("NEXTLINE")
proc doublize(j:JsonNode)=
  var c:CountTable[float]
  for i,l in j["judgeLineList"].getElems.pairs:
    for m,la in l["eventLayers"].getElems.pairs:
      if la.kind==JNull:continue
      var ks:seq[string]
      for k,es in la.pairs:
        ks.add k
        for e in es:
          e["startTimeS"]=newJFloat(B2S(e["startTime"].time2B(),j["BPMList"].getElems()))
          e["endTimeS"]=newJFloat(B2S(e["endTime"].time2B(),j["BPMList"].getElems()))
      for k in ks:
        la[k&"I"]=newJInt(0)
    if "notes" in l:
      for e in l["notes"]:
        e["startTimeS"]=newJFloat(B2S(e["startTime"].time2B(),j["BPMList"].getElems()))
        e["endTimeS"]=newJFloat(B2S(e["endTime"].time2B(),j["BPMList"].getElems()))
        c.inc(e["startTime"][0].getFloat+e["startTime"][1].getInt/e["startTime"][2].getInt)
  for l in j["judgeLineList"]:
    if "notes" in l:
      for e in l["notes"]:
        e["hl"]=newJInt BiggestInt(c[e["startTime"][0].getFloat+e["startTime"][1].getInt/e["startTime"][2].getInt]>1)
proc tranRPE*(path:string)=
  let (d,_,_)=splitFile(path)
  block gen:
    var j=json.parseFile(path)
    j.doublize()
    var f=open(d/("rawChart.bin"),fmWrite)
    defer:f.close()
    var s=newFileStream(f)
    defer:s.close()
    tran(j,s)
  optimize(d/("rawChart.bin"))
