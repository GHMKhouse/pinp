import sdl2_nim/[sdl, sdl_ttf, sdl_gpu]
import globals
const
  white* = Color(r:255,g:255,b:255,a:255)
type
  TextRenderingCacheObj* = object
    str*:cstring
    surf:Surface
    img:Image
  TextRenderingCache* = ref TextRenderingCacheObj
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
proc put*[T,U,V,W,X:SomeNumber](trc:TextRenderingCache,target:Target,x:T,y:U,r:V,w:W,h:X)=
  trc.img.blitTransform(nil,target,x.float32,y.float32,r.float32,w.float32,h.float32)
proc setRGBA*(trc:TextRenderingCache,r,g,b,a:uint8)=
  trc.img.setRGBA(r,g,b,a)