import sdl2_nim/[sdl, sdl_ttf, sdl_gpu, sdl_mixer]
import options,types
var
  target*: Target
  window*: Window
  scrnWidth*: int = 1600
  scrnHeight*: int = 900
  maxWidth*, maxHeight*: cint
  font16*, font32*, font64*: Font
  music*:Music
  hitSounds*:array[NoteKind,Chunk]
  channelQ*:int
  tex*:array[Tex,Image]
  bg*:Image
  chart*:Chart
  playing*:bool
  beginEpoch*:int
  time*:float32=0.0
  hitFXs*:seq[tuple[time:float32,x:float32,y:float32,j:Judge]]
  combo*:int
  globalScale*:float32=getOption("PLAY","globalScale").intVal/1000
  minLineAlpha*:float32=getOption("PLAY","minLineAlpha").intVal.toFloat
  speedScale*:float32=getOption("PLAY","speedScale").intVal/1000