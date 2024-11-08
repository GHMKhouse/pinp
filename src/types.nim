import json,oids
import sdl2_nim/[sdl,sdl_ttf,sdl_gpu]
var
  font16*, font32*, font64*: Font
const
  white* = Color(r:255,g:255,b:255,a:255)
  red* = Color(r:255,g:0,b:0,a:255)
  yellow* = Color(r:255,g:255,b:0,a:255)
  green* = Color(r:0,g:255,b:0,a:255)
  cyan* = Color(r:0,g:255,b:255,a:255)
  blue* = Color(r:0,g:0,b:255,a:255)
  purple* = Color(r:255,g:0,b:255,a:255)

type
  TIter*[T] = ref object
    i*:int
    s*:seq[T]
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
    xe*,ye*,re*,ae*,fe*:TIter[LEvent]
    n*:seq[Note]
  LEvent* = object
    t1*,t2*:float32   # in seconds
    v1*,v2*:float64   # x,y:[-0.5,0.5],r:[-360,360],a:[0,1]
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
    f1*,f2*:float64
    judge*:Judge=jUnjudged
    lastHitFX*:int64
    lastHold*:int64
  Touch* = object
    time*:float32
    x*:float32
    y*:float32
    noEarly*:bool
    parentClick*:ptr Touch
  Layers* = ref object
    kind*:string
    top*:JsonNode
  TextRenderingCacheObj* = object
    str*:cstring
    surf*:Surface
    img*:Image
  TextRenderingCache* = ref TextRenderingCacheObj
  MenuMap* = ref object
    id*:Oid
    title*,level*,composer*,charter*,illustrator*,path*:string
    ttitle*,tlevel*,tcomposer*,tcharter*,tillustrator*:TextRenderingCache
  MainReturn* = enum
    mrQuit
    mrRestart
    mrEnd
proc `=destroy`*(trc:TextRenderingCacheObj)=
  if not trc.img.isNil:
    freeImage(trc.img)
  if not trc.surf.isNil:
    freeSurface(trc.surf)
proc newTextRenderingCache*(str:string,color:Color,anchorX:float32,anchorY:float32):TextRenderingCache=
  new result
  result.str=cstring(str)
  result.surf=font64.renderUTF8_Blended(result.str,color)
  result.img=copyImageFromSurface(result.surf)
  result.img.setAnchor(anchorX,anchorY)
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,noEarly:bool]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,noEarly:t.noEarly)
converter toTouch*(t:tuple[time:float32,x:float32,y:float32,parentClick:ptr Touch]):Touch=
  Touch(time:t.time,x:t.x,y:t.y,parentClick:t.parentClick)
var nk2order*:array[NoteKind,int]=[0,2,1,3]
var j2order*:array[Judge,int]=[0,3,2,1,1,3,2]
proc `<`*(x,y:Judge):bool=
  j2order[x]<j2order[y]
proc `[]`*[T](l:TIter[T],i:Natural):T=
  l.s[i]
proc len*[T](l:TIter[T]):int=
  l.s.len
proc `[]=`*[T](l:TIter[T],i:Natural,v:T)=
  l.s[i]=v
proc add*[T](l:TIter[T],v:T)=
  l.s.add v
iterator items*[T](l:TIter[T]):T=
  for i in l.i..<l.len:
    yield l[i]
iterator pairs*[T](l:TIter[T]):(int,T)=
  for i in l.i..<l.len:
    yield (i,l[i])
proc toTIter*[T](l:seq[T]):TIter[T]=
  new result
  result.i=0
  result.s=l
proc toLayers*(t:JsonNode,k:string):Layers=
  new result
  result.top=t
  result.kind=k
proc newMenuMap*(id:Oid;title,level,composer,charter,illustrator,path:string):MenuMap=
  new result
  result.id=id
  result.title=title
  result.ttitle=newTextRenderingCache(title,white,0.0,0.0)
  result.level=level
  result.tlevel=newTextRenderingCache(level,white,0.0,0.0)
  result.composer=composer
  result.tcomposer=newTextRenderingCache(composer,white,0.0,0.0)
  result.charter=charter
  result.tcharter=newTextRenderingCache(charter,white,0.0,0.0)
  result.illustrator=illustrator
  result.tillustrator=newTextRenderingCache(illustrator,white,0.0,0.0)
  result.path=path