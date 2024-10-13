import json
type
  Tex* {.pure.} = enum 
    line,tap,tapHL,drag,dragHL,flick,flickHL,
    holdBody,holdBodyHL,holdTail,holdTailHL,holdHead,holdHeadHL,pause,hitFX
  Chart* = ref object
    offset*:float32   # in seconds
    constSpeed*:bool
    lines*:seq[JLine]
    numOfNotes*:int
    songLength*:float32
  JLine* = ref object
    xe*,ye*,re*,ae*,fe*:seq[LEvent]
    n*:seq[Note]
  LEvent* = object
    t1*,t2*:float32   # in seconds
    v1*,v2*:float32   # x,y:[-0.5,0.5],r:[-360,360],a:[0,1]
  NoteKind* = enum nkTap,nkDrag,nkHold,nkFlick
  Judge* = enum jUnjudged,jPerfect,jGood,jBad,jMiss,jHoldingPerfect,jHoldingGood
  Note* = ref object
    t1*,t2*:float32
    x*:float32
    nx*,ny*,r*:float32
    speed*:float32
    below*:bool       # flags[2]
    real*:bool        # flags[3]
    hl*:bool          # flags[4]
    kind*:NoteKind    # flags[0..1]
    f1*,f2*:float32
    judge*:Judge=jUnjudged
    lastHitFX*:int64
    lastHold*:int64
  Touch* = object
    time*:float32
    x*:float32
    y*:float32
    noEarly*:bool
    parentClick*:ptr Touch
  TIter*[T:typedesc;U:typedesc[iterable[T]]] = ref object
    i*:int
    s*:U
  Layers* = ref object
    kind*:string
    top*:JsonNode
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,noEarly:bool]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,noEarly:t.noEarly)
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,parentClick:ptr Touch]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,parentClick:t.parentClick)
var nk2order*:array[NoteKind,int]=[0,2,1,3]
var j2order*:array[Judge,int]=[0,3,2,1,1,3,2]

proc `<`*(x,y:Judge):bool=
  j2order[x]<j2order[y]
proc `[]`*[T:typedesc;U:typedesc[iterable[T]]](l:TIter[T,U],i:Natural):T=
  l.s[i]
proc len*[T:typedesc;U:typedesc[iterable[T]]](l:TIter[T,U],i:Natural):T=
  l.s.len
iterator items*[T:typedesc;U:typedesc[iterable[T]]](l:TIter[T,U]):T=
  for i in l.i..<l.len:
    yield l[i]
iterator pairs*[T:typedesc;U:typedesc[iterable[T]]](l:TIter[T,U]):(int,T)=
  for i in l.i..<l.len:
    yield (i,l[i])
proc toTIter*[T:typedesc;U:typedesc[iterable[T]]](l:U):TIter[T,U]=
  new result
  result.i=0
  result.s=l
proc toLayers*(t:JsonNode,k:string):Layers=
  new result
  result.top=t
  result.kind=k