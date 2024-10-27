import tables,typeinfo
import sdl2_nim/[sdl,sdl_gpu]
import globals
proc beginLoadingScreen(data:ptr Table[string,Any])=
  echo 3
  var
    target=cast[ptr Target](data[]["target"].getPointer)[]
    bg=cast[ptr Image](data[]["bgImg"].getPointer)[]
    loaded=cast[ptr bool](data[]["loaded"].getPointer)
  echo 4
  while not loaded[]:
    var event:Event
    while pollEvent(event.addr)==1:
      discard
    target.clear()
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale,
      scrnHeight.int/bg.h.int*globalScale)
    target.flip()
  echo 5
proc beginLoadingScreen*(data:pointer):cint{.cdecl.}=
  beginLoadingScreen(cast[ptr Table[string,Any]](data))
  return 0