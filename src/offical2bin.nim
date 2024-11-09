import std/[json,os,tables,streams,strutils]
import bitflags,optimizer
proc getSongLength(j:JsonNode):float32=
  for l in j["judgeLineList"]:
    var bps=l["bpm"].getFloat/60
    for e in l["judgeLineMoveEvents"]:
      result=max(result,e["startTime"].getFloat/32/bps)
    for e in l["judgeLineMoveEvents"]:
      result=max(result,e["startTime"].getFloat/32/bps)
    for e in l["judgeLineRotateEvents"]:
      result=max(result,e["startTime"].getFloat/32/bps)
    for e in l["judgeLineDisappearEvents"]:
      result=max(result,e["startTime"].getFloat/32/bps)
    for e in l["notesAbove"]:
      result=max(result,e["time"].getFloat/32/bps)
    for e in l["notesBelow"]:
      result=max(result,e["time"].getFloat/32/bps)
proc tranOffical*(j:JsonNode,s:var FileStream)=
  s.write uint32(0)
  s.write float32(j["offset"].getFloat)
  s.write j.getSongLength()
  s.write uint32(1)
  template begin(name:string)=
    s.write uint32.high
    s.write name.alignLeft(12)
  for l in j["judgeLineList"]:
    var bps=l["bpm"].getFloat/60
    begin("MOVEX")
    for e in l["judgeLineMoveEvents"]:
      s.write float32(e["startTime"].getFloat/32/bps)
      s.write float32(e["endTime"].getFloat/32/bps)
      s.write float32(e["start"].getFloat-0.5)
      s.write float32(e["end"].getFloat-0.5)
    begin("MOVEY")
    for e in l["judgeLineMoveEvents"]:
      s.write float32(e["startTime"].getFloat/32/bps)
      s.write float32(e["endTime"].getFloat/32/bps)
      s.write float32(e["start2"].getFloat-0.5)
      s.write float32(e["end2"].getFloat-0.5)
    begin("ROTATE")
    for e in l["judgeLineRotateEvents"]:
      s.write float32(e["startTime"].getFloat/32/bps)
      s.write float32(e["endTime"].getFloat/32/bps)
      s.write float32(e["start"].getFloat)
      s.write float32(e["end"].getFloat)
    begin("ALPHA")
    for e in l["judgeLineDisappearEvents"]:
      s.write float32(e["startTime"].getFloat/32/bps)
      s.write float32(e["endTime"].getFloat/32/bps)
      s.write float32(e["start"].getFloat)
      s.write float32(e["end"].getFloat)
    begin("FLOOR")
    var floor=0.0
    for e in l["speedEvents"]:
      s.write float32(e["startTime"].getFloat/32/bps)
      s.write float32(e["endTime"].getFloat/32/bps)
      s.write float64(floor)
      floor+=(e["endTime"].getFloat-e["startTime"].getFloat)/32*
        e["value"].getFloat
      s.write float64(floor)
      s.write uint64(0)                                   # reserved
    begin("NOTES")
    for e in l["notesAbove"]:
      s.write float32(e["time"].getFloat/32/bps)
      s.write float32((e["time"].getFloat+e["holdTime"].getFloat)/32/bps)
      s.write float32(e["positionX"].getFloat/6)
      s.write float32(e["speed"].getFloat*(if e["type"].getInt==3:bps else:1))
      s.write uint32((e["type"].getInt-1) or
        NoteAbove or NoteReal or (e["hl"].getInt shl 4))
      s.write uint32(0)
      s.write uint64(0)                                   # reserved
      s.write float64(e["floorPosition"].getFloat*bps)
      s.write float64(e["floorPosition"].getFloat*bps+
        e["holdTime"].getFloat/32*e["speed"].getFloat)
    for e in l["notesBelow"]:
      s.write float32(e["time"].getFloat/32/bps)
      s.write float32((e["time"].getFloat+e["holdTime"].getFloat)/32/bps)
      s.write float32(e["positionX"].getFloat/6)
      s.write float32(e["speed"].getFloat*(if e["type"].getInt==3:bps else:1))
      s.write uint32((e["type"].getInt-1) or
        NoteBelow or NoteReal or (e["hl"].getInt shl 4))
      s.write uint32(0)
      s.write uint64(0)
      s.write float64(e["floorPosition"].getFloat*bps)
      s.write float64(e["floorPosition"].getFloat*bps+
        e["holdTime"].getFloat/32*e["speed"].getFloat)
    begin("NEXTLINE")
proc doublize(j:JsonNode)=
  var c:CountTable[float]
  for l in j["judgeLineList"]:
    for e in l["notesAbove"]:
      c.inc(e["time"].getFloat)
    for e in l["notesBelow"]:
      c.inc(e["time"].getFloat)
  for l in j["judgeLineList"]:
    for e in l["notesAbove"]:
      e["hl"]=newJInt BiggestInt(c[e["time"].getFloat]>1)
    for e in l["notesBelow"]:
      e["hl"]=newJInt BiggestInt(c[e["time"].getFloat]>1)
proc tranOffical*(path:string)=
  let (d,_,_)=splitFile(path)
  block gen:
    var j=json.parseFile(path)
    j.doublize()
    var f=open(d/("rawChart.bin"),fmWrite)
    defer:f.close()
    var s=newFileStream(f)
    defer:s.close()
    tranOffical(j,s)
  optimize(d/("rawChart.bin"))