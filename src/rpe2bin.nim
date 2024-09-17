when false:                    # not finished
  import std/[json,os,tables,streams]
  template time2B(x:JsonNode):float=
    x[0].num.float+x[1].num/x[2].num
  iterator iterSlice[T](x:seq[T],s:Slice[int]): T=
    for i in s:
      yield x[i]
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
      for la in l["eventLayers"]:
        for e in ["alphaEvents","moveXEvents","moveYEvents","rotateEvents"]:
          result=max(result,B2S(la[e][^1]["endTime"].time2B(),j["BPMList"].getElems()))
  proc cutEvent(s:var FileStream;t1,t2,x1,x2:float32,easing:int)=
    for i in int(t1*48)..<int(t2*48):
      s.write()
    discard
  proc tran*(j:JsonNode,s:var FileStream)=
    s.write uint32(j["META"]["offset"].getFloat/1000)
    s.write j.getSongLength()
    s.write uint32(1)
    for l in j["judgeLineList"]:
      let la=l["eventLayers"][0]
      #for la in l["eventLayers"]:
      #for e in ["moveXEvents","moveYEvents","rotateEvents","alphaEvents"]:
      for n in la["moveXEvents"]:
        s.cutEvent(
          float32(B2S(n["startTime"].time2B(),j["BPMList"].getElems())),
          float32(B2S(n["endTime"].time2B(),j["BPMList"].getElems())),
          float32(n["start"].getFloat/1350),
          float32(n["end"].getFloat/1350),
          n["easingType"].getInt
        )
      for n in la["speedEvents"]:
        s.write float32(B2S(n["startTime"].time2B(),j["BPMList"].getElems()))
        s.write float32(B2S(n["endTime"].time2B(),j["BPMList"].getElems()))
        s.write float32(e["start"].getFloat/1350)
        s.write float32(e["end"].getFloat/1350)
      for e in l["judgeLineDisappearEvents"]:
        s.write float32(e["startTime"].getFloat/32/bps)
        s.write float32(e["endTime"].getFloat/32/bps)
        s.write float32(e["start"].getFloat)
        s.write float32(e["end"].getFloat)
      s.write uint32.high
      var floor=0.0
      for e in l["speedEvents"]:
        s.write float32(e["startTime"].getFloat/32/bps)
        s.write float32(e["endTime"].getFloat/32/bps)
        s.write float32(floor)
        floor+=(e["endTime"].getFloat-e["startTime"].getFloat)/32*e["value"].getFloat
        s.write float32(floor)
      s.write uint32.high
      for e in l["notesAbove"]:
        s.write float32(e["time"].getFloat/32/bps)
        s.write float32((e["time"].getFloat+e["holdTime"].getFloat)/32/bps)
        s.write float32(e["positionX"].getFloat/6)
        s.write float32(e["speed"].getFloat*(if e["type"].getInt==3:bps else:1))
        s.write uint32((e["type"].getInt-1) or 0b000 or 0b1000 or (e["hl"].getInt shl 4))
        s.write float32(e["floorPosition"].getFloat*bps)
        s.write float32(e["floorPosition"].getFloat*bps+e["holdTime"].getFloat/32*e["speed"].getFloat)
      for e in l["notesBelow"]:
        s.write float32(e["time"].getFloat/32/bps)
        s.write float32((e["time"].getFloat+e["holdTime"].getFloat)/32/bps)
        s.write float32(e["positionX"].getFloat/6)
        s.write float32(e["speed"].getFloat*(if e["type"].getInt==3:bps else:1))
        s.write uint32((e["type"].getInt-1) or 0b100 or 0b1000 or (e["hl"].getInt shl 4))
        s.write float32(e["floorPosition"].getFloat*bps)
        s.write float32(e["floorPosition"].getFloat*bps+e["holdTime"].getFloat/32*e["speed"].getFloat)
      s.write uint32.high
  proc doublize(j:JsonNode)=
    var c:CountTable[float]
    for l in j["judgeLineList"]:
      for e in l["notes"]:
        c.inc(e["time"][0].getFloat+e["time"][1].getInt/e["time"][2].getInt)
    for l in j["judgeLineList"]:
      for e in l["notes"]:
        e["hl"]=newJInt BiggestInt(c[e["time"][0].getFloat+e["time"][1].getInt/e["time"][2].getInt]>1)
  proc tran*(path:string)=
    let (d,_,_)=splitFile(path)
    var j=json.parseFile(path)
    j.doublize()
    var f=open(d/("rawChart.bin"),fmWrite)
    defer:f.close()
    var s=newFileStream(f)
    defer:s.close()
    tran(j,s)