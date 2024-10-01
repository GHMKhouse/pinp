import tables
import sdl2_nim/[sdl,sdl_gpu]
import globals
proc beginLoadingScreen*(data:ptr Table[string,pointer]){.thread,nimcall.}=
  var
    target=cast[ptr Target](data[]["target"])[]
    bg=cast[ptr Image](data[]["bgImg"])[]
    loaded=cast[ptr bool](data[]["loaded"])
  while not loaded[]:
    target.clear()
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale,
      scrnHeight.int/bg.h.int*globalScale)
    target.flip()