import std/[streams,strutils]
import bitflags,types
  
proc loadBin(s:Stream):Chart=
  new result
  let version=s.readUint32() # u8.u8.u8.u8
  if version>=0:
    result.offset=s.readFloat32()
    result.songLength=s.readFloat32()
    var flags=s.readUint32()
    result.constSpeed=bool(flags and 1)
  
  proc readEvent(s:Stream):LEvent=
    if version>=0:
      result.t1=s.readFloat32()
      result.t2=s.readFloat32()
      result.v1=s.readFloat32().float64
      result.v2=s.readFloat32().float64
  proc readFloorEvent(s:Stream):LEvent=
    if version>=0:
      result.t1=s.readFloat32()
      result.t2=s.readFloat32()
      result.v1=s.readFloat64()
      result.v2=s.readFloat64()
      doAssert s.readUint64()==0
  
  while not s.atEnd:
    var l:JLine
    new l
    l.xe=toTIter(newSeqOfCap[LEvent](1024))
    l.ye=toTIter(newSeqOfCap[LEvent](1024))
    l.re=toTIter(newSeqOfCap[LEvent](1024))
    l.ae=toTIter(newSeqOfCap[LEvent](1024))
    l.fe=toTIter(newSeqOfCap[LEvent](1024))
    while true:
      if s.atEnd():break
      doAssert s.readUint32()==uint32.high
      let n=s.readStr(12).strip()
      var e:TIter[LEvent]
      case n
      of "MOVEX":
        e=l.xe
      of "MOVEY":
        e=l.ye
      of "ROTATE":
        e=l.re
      of "ALPHA":
        e=l.ae
      of "FLOOR":
        e=l.fe
        while s.peekUInt32()!=uint32.high:
          e.add readFloorEvent(s)
      of "NOTES":
        while s.peekUInt32()!=uint32.high:
          var n:Note
          new n
          if version>=0:
            n.t1=s.readFloat32()
            n.t2=s.readFloat32()
            n.x=s.readFloat32()
            n.speed=s.readFloat32()
            let flags=s.readUInt32()
            n.kind=cast[NoteKind](flags and NoteKindMask)
            n.below=bool(flags and NoteSideMask)
            n.real=bool(flags and NoteRealMask)
            n.hl=bool(flags and NoteHLMask)
            doAssert s.readUint32()==0
            doAssert s.readUint64()==0
            n.f1=s.readFloat64()
            n.f2=s.readFloat64()
            if n.real:
              inc result.numOfNotes
          l.n.add n
      of "NEXTLINE":
        break
      else:
        continue
      while s.peekUInt32()!=uint32.high:
        e.add readEvent(s)
    result.lines.add l

proc loadBin*(path:string):Chart=
  var f=open(path,fmRead)
  defer:f.close()
  var b=f.readAll()
  var s=newStringStream(b)
  defer:s.close()
  result = loadBin(s)