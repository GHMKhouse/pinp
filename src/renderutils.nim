import sdl2_nim/[sdl_gpu]
import types
proc put*[T,U,V,W,X:SomeNumber](trc:TextRenderingCache,target:Target,x:T,y:U,r:V,w:W,h:X)=
  trc.img.blitTransform(nil,target,x.float32,y.float32,r.float32,w.float32,h.float32)
proc setRGBA*(trc:TextRenderingCache,r,g,b,a:uint8)=
  trc.img.setRGBA(r,g,b,a)
proc w*(trc:TextRenderingCache):uint16=
  trc.img.w
proc h*(trc:TextRenderingCache):uint16=
  trc.img.h
proc setAnchor*(trc:TextRenderingCache,x,y:float32)=
  trc.img.setAnchor(x,y)