import sdl2_nim/[sdl]
proc handleEvent*(event:Event)=
  case event.kind
  of QUIT:quit(QuitSuccess)
  else:discard