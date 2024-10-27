when true:                    # not finished
  import std/[json,os,tables,streams]
  import easings,tools,types
  const dt=0.008
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
    if bpmList.len==1:
      return (x/lastBPM["bpm"].getFloat*60)
    for bpm in bpmList.iterSlice(1..<bpmList.len):
      if time2B(bpm["startTime"])>x:
        result += ((x-time2B(lastbpm["startTime"]))/lastBPM["bpm"].getFloat*60)
        break
      else:
        result += ((time2B(bpm["startTime"])-time2B(lastbpm["startTime"]))/lastBPM["bpm"].getFloat*60)
        lastBPM=bpm
    return 
  proc getSongLength(j:JsonNode):float32=
    for l in j["judgeLineList"]:
      if "notes" in l:
        for n in l["notes"]:
          result=max(result,B2S(n["endTime"].time2B(),j["BPMList"].getElems()))
      for la in l["eventLayers"]:
        for e in ["alphaEvents","moveXEvents","moveYEvents","rotateEvents"]:
          if e in la:
            result=max(result,B2S(la[e][^1]["endTime"].time2B(),j["BPMList"].getElems()))
    j["songLength"]=newJFloat(result)
  proc calcL(events:seq[(float32,float32,float32,float32)],t:float32):float32=
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

  proc calc(layers:Layers,t:float32):float32=
    result=0.0
    for layer in layers.top.getElems:
      if layers.kind in layer:
        for i in layer[layers.kind&"I"].getInt..<layer[layers.kind].len:
          layer[layers.kind&"I"]=newJInt(i)
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
      lt:float32=(l["eventLayers"][0][kind][0]["startTimeS"].getFloat)
      lv:float32=calc(l["eventLayers"].toLayers(kind),lt)
    l["eventLayers"][0][kind&"I"]=newJInt(0)
    yield (-99999.99'f32,lt,lv,lv)
    if l["father"].getInt==(-1):
      for t in xrange(0,j["songLength"].getFloat,dt):
        var
          v=calc(l["eventLayers"].toLayers(kind),t)
        if abs(v-lv)>0.000001:
          yield (lt,t,v,v)
        lt=t
        lv=v
  proc tran*(j:JsonNode,s:var FileStream)=
    s.write uint32(0)
    s.write uint32(j["META"]["offset"].getFloat/1000)
    s.write j.getSongLength()
    s.write uint32(0)
    for i,l in j["judgeLineList"].getElems.pairs:
      for e in tran(j,i,"moveXEvents"):
        let (t1,t2,v1,v2)=e
        s.write t1
        s.write t2
        s.write v1/1350
        s.write v2/1350
      s.write uint32.high
      for e in tran(j,i,"moveYEvents"):
        let (t1,t2,v1,v2)=e
        s.write t1
        s.write t2
        s.write v1/900
        s.write v2/900
      s.write uint32.high
      for e in tran(j,i,"rotateEvents"):
        let (t1,t2,v1,v2)=e
        s.write t1
        s.write t2
        s.write -v1
        s.write -v2
      s.write uint32.high
      for e in tran(j,i,"alphaEvents"):
        let (t1,t2,v1,v2)=e
        s.write t1
        s.write t2
        s.write v1/255
        s.write v2/255
      s.write uint32.high
      var floorEvents:seq[(float32,float32,float32,float32)]
      var
        floor:float32=0.0
        lt:float32=(-99999.9)
        ls:float32=10.0
      template addFloorEvent(t1,t2,f1,f2:float32)=
        s.write t1
        s.write t2
        s.write f1*1.2'f32
        s.write f2*1.2'f32
        floorEvents.add (t1,t2,f1*1.2'f32,f2*1.2'f32)
      for e in l["eventLayers"][0]["speedEvents"]:
        let lf=floor
        floor+=(e["startTimeS"].getFloat-lt)*ls
        addFloorEvent(lt,e["startTimeS"].getFloat.float32,lf,floor)
        if abs(e["start"].getFloat-e["end"].getFloat)<0.00001:
          let t1=float32(e["startTimeS"].getFloat)
          let t2=float32(e["endTimeS"].getFloat)
          let f1=float32(floor)
          floor+=(t2-t1)*e["start"].getFloat
          let f2=float32(floor)
          addFloorEvent(t1,t2,f1,f2)
          lt=t2
          ls=e["end"].getFloat
        else:
          for t in xrange(e["startTimeS"].getFloat,e["endTimeS"].getFloat-dt,dt):
            let
              t1=t
              t2=t+dt
              f1=float32(floor)
            floor+=dt*(e["start"].getFloat+(e["end"].getFloat-e["start"].getFloat)*(t+dt/2-e["startTimeS"].getFloat)/(e["endTimeS"].getFloat-e["startTimeS"].getFloat))
            addFloorEvent(t1,t2.float32,f1,floor.float32)
          lt=e["endTimeS"].getFloat
          ls=e["end"].getFloat
      let lf=floor
      floor+=(j["songLength"].getFloat+9999.99-lt)*ls
      addFloorEvent(lt,j["songLength"].getFloat.float32+9999.99'f32,lf,floor)
      s.write uint32.high
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
          s.write float32(calcL(floorEvents,e["startTimeS"].getFloat))
          s.write float32(calcL(floorEvents,e["endTimeS"].getFloat))
      s.write uint32.high
  proc doublize(j:JsonNode)=
    var c:CountTable[float]
    for i,l in j["judgeLineList"].getElems.pairs:
      for m,la in l["eventLayers"].getElems.pairs:
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
    var j=json.parseFile(path)
    j.doublize()
    var f=open(d/("rawChart.bin"),fmWrite)
    defer:f.close()
    var s=newFileStream(f)
    defer:s.close()
    tran(j,s)