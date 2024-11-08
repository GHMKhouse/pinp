import std/[streams,strutils]
import types
proc saveBin(c:Chart,s:Stream)=
  s.write uint32(0)
  s.write float32(c.offset)
  s.write float32(c.songLength)
  s.write uint32(c.constSpeed.int)
  proc writeEvent(s:Stream,e:LEvent)=
    s.write float32(e.t1)
    s.write float32(e.t2)
    s.write float32(e.v1)
    s.write float32(e.v2)
  proc writeFloorEvent(s:Stream,e:LEvent)=
    s.write float32(e.t1)
    s.write float32(e.t2)
    s.write float64(e.v1)
    s.write float64(e.v2)
    s.write uint64(0)
  template begin(name:string)=
    s.write uint32.high
    s.write name.alignLeft(12)
  for l in c.lines:
    begin("MOVEX")
    for e in l.xe:
      s.writeEvent(e)
    begin("MOVEY")
    for e in l.ye:
      s.writeEvent(e)
    begin("ROTATE")
    for e in l.re:
      s.writeEvent(e)
    begin("ALPHA")
    for e in l.ae:
      s.writeEvent(e)
    begin("FLOOR")
    for e in l.fe:
      s.writeFloorEvent(e)
    begin("NOTES")
    for n in l.n:
      s.write float32(n.t1)
      s.write float32(n.t2)
      s.write float32(n.x)
      s.write float32(n.speed)
      s.write uint32(
        (n.kind.int) or
        (n.below.int shl 2) or
        (n.real.int shl 3) or
        (n.hl.int shl 4))
      s.write uint32(0)
      s.write uint64(0)
      s.write float64(n.f1)
      s.write float64(n.f2)
    begin("NEXTLINE")
proc savebin*(path:string,c:Chart)=
  var f=open(path,fmWrite)
  defer:f.close()
  var s=newFileStream(f)
  defer:s.close()
  saveBin(c,s)