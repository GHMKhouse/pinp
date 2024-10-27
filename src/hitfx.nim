import std/[math,random]
import sdl2_nim/[sdl,sdl_gpu]
import globals,types
proc renderHitFX* =
  var
    dels:seq[int]
    deloffset:int=0
  for i in 0..<hitFXs.len:
    let (t,x,y,h,j)=hitFXs[i]
    if time-t>0.5 or j==jMiss:
      dels.add i
    elif j==jBad:
      tex[Tex.tap].setRGBA(255,0,0,uint8(192*(0.5-time+t)))
      tex[Tex.tap].blitTransform(nil,target,
        x,y,h,0.2*globalScale*sizeFactor,0.2*globalScale*sizeFactor)
    else:
      var rect=makeRect(
        cfloat(256*(int((time-t)*60) mod 6)),
        cfloat(256*(int((time-t)*60) div 6)),256,256)
      let (r,g,b)=case j
      of jPerfect,jHoldingPerfect:(237'u8,236'u8,176'u8)
      of jGood,jHoldingGood:(180,225,255)
      else:(0,0,0)
      var rn=initRand(  # no need to create particle objects.
        int(256*t) or (int(x*256) shl 8) or
        (int(y*256) shl 16) or (int(j) shl 24))
      for i in 0..7:
        let
          px:float32=(sqrt(float32(rn.next() mod uint32.high))-
            uint16.high.float/sqrt(3'f32))/128*sqrt(time-t)*globalScale
          py:float32=(sqrt(float32(rn.next() mod uint32.high))-
            uint16.high.float/sqrt(3'f32))/128*sqrt(time-t)*globalScale
        target.rectangleFilled(
          x+px-12*globalScale,y+py-12*globalScale,
          x+px+12*globalScale,y+py+12*globalScale,
          makeColor(r,g,b,uint8(255-255*sqrt(time-t))))
      tex[Tex.hitFX].setRGB(r,g,b)
      tex[Tex.hitFX].blitScale(rect.addr,target,
        x,y,1.0*globalScale,1.0*globalScale)
  for d in dels:
    hitFXs.delete(d-deloffset)
    inc deloffset