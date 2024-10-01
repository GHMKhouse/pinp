
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
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,noEarly:bool]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,noEarly:t.noEarly)
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,parentClick:ptr Touch]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,parentClick:t.parentClick)
var nk2order*:array[NoteKind,int]=[0,2,1,3]
var j2order*:array[Judge,int]=[0,3,2,1,1,3,2]

proc `<`*(x,y:Judge):bool=
  j2order[x]<j2order[y]