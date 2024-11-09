import std/[tables]
import sdl2_nim/[sdl, sdl_gpu, sdl_mixer]
import options,types
import iniplus
var
  target*: Target
  window*: Window
  scrnWidth*: int = getOption("GENERAL","scrnWidth").intVal
  playWidth*: int = int(getOption("GENERAL","scrnHeight").intVal*16/9)
  scrnHeight*: int = getOption("GENERAL","scrnHeight").intVal
  sizeFactor*: float32 = scrnHeight/900*getOption("PLAY","noteSize").intVal.float/1000
  maxWidth*, maxHeight*: cint
  music*:Music
  hitSounds*:array[NoteKind,Chunk]
  channelQ*:int
  tex*:array[Tex,Image]
  bg*:Image
  chart*:Chart
  playing*:bool
  beginEpoch*:int
  time*:float32=0.0
  hitFXs*:seq[tuple[time:float32,x:float32,y:float32,h:float32,j:Judge]]
  combo*:int
  globalScale*:float32=getOption("PLAY","globalScale").intVal/1000
  minLineAlpha*:float32=getOption("PLAY","minLineAlpha").intVal.toFloat
  speedScale*:float32=getOption("PLAY","speedScale").intVal/1000
  autoPlay*:bool=getOption("PLAY","autoPlay").intVal.bool
  startTime*:float32=getOption("PLAY","startTime").intVal/1000
  noteSize*:float32=getOption("PLAY","noteSize").intVal/1000
  maxFPS*:int=getOption("PLAY","maxFPS").intVal
  loadingDelay*:int=getOption("DEBUG","loadingDelay").intVal
  clicks*:Table[TouchID,Touch]
  touchs*:Table[TouchID,Touch]
  flicks*:Table[TouchID,Touch]
  keyInputs*:Table[TouchID,Touch]
  playResult*:array[Judge,int]
  jNotes*:seq[Note]
  gui*:Table[string,Image]
  trcs*:Table[string,TextRenderingCache]
  snds*:Table[string,Chunk]
  maps*:seq[MenuMap]
  crtMap*:MenuMap
  info*:ConfigTable
  illustInfo*:string
  musicInfo*:string
  chartInfo*:string
  title*:string
  level*:string
  composer*:string
  charter*:string
  illustrator*:string