import std/[streams]
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
      result.v1=s.readFloat32()
      result.v2=s.readFloat32()
  
  while not s.atEnd:
    var l:JLine
    new l
    while s.peekUInt32()!=uint32.high:
      l.xe.add readEvent(s)
    doAssert s.readUint32()==uint32.high
    while s.peekUInt32()!=uint32.high:
      l.ye.add readEvent(s)
    doAssert s.readUint32()==uint32.high
    while s.peekUInt32()!=uint32.high:
      l.re.add readEvent(s)
    doAssert s.readUint32()==uint32.high
    while s.peekUInt32()!=uint32.high:
      l.ae.add readEvent(s)
    doAssert s.readUint32()==uint32.high
    while s.peekUInt32()!=uint32.high:
      l.fe.add readEvent(s)
    doAssert s.readUint32()==uint32.high
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
        n.f1=s.readFloat32()
        n.f2=s.readFloat32()
        inc result.numOfNotes
      l.n.add n
    doAssert s.readUint32()==uint32.high
    result.lines.add l

proc loadBin*(path:string):Chart=
  var f=open(path,fmRead)
  defer:f.close()
  var b=f.readAll()
  var s=newStringStream(b)
  defer:s.close()
  return loadBin(s)