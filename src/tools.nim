
import std/[macros,monotimes,options]
import sdl2_nim/[sdl,sdl_gpu]

macro doSDL*(x: cint) =
  ## Catch errors during sdl operations.
  let s = x.repr
  result = quote do:
    if `x` < 0:
      quit getStackTrace() & `s` & " failed:" & $sdl.getError()
  result.setLineInfo(x.lineInfoObj)
template section*(z,x)=x
template benchmark*(x:untyped)=
  let st=getMonoTime().ticks()
  x
  echo getMonoTime().ticks()-st
proc `/`*(x:SomeInteger,y:SomeInteger):auto=int(x)/int(y)
template optional*[T](x:T):Option[T]=
  try:
    some(x)
  except IndexDefect,CatchableError:
    none(T)