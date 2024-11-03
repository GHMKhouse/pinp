import std/[lenientops,strutils,tables]
import sdl2_nim/[sdl,sdl_gpu,sdl_mixer]
import iniplus
import globals,renderutils,tools,types
proc over*:MainReturn=
  var score=newTextRenderingCache(
    align($(int((playResult[jPerfect].float+playResult[jGood]/2)/chart.numOfNotes.float*1000000)),7,'0'),
    white,1.0,0.0)
  doSDL:playChannel(0,snds["over"],-1)
  for i in 0..60:
    target.clear()
    bg.setRGBA(128,128,128,255)
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale,
      scrnHeight.int/bg.h.int*globalScale)
    gui["loadingbg_up"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(i/60),scrnWidth.float32,scrnHeight.float32)
    gui["loadingbg_down"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(2-i/60),scrnWidth.float32,scrnHeight.float32)
    bg.setRGBA(255,255,255,uint8(4*i+15))
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale/2,
      scrnHeight.int/bg.h.int*globalScale/2)
    tex[Tex.pause].setRGBA(255,255,255,uint8(4*i+15))
    tex[Tex.pause].blitScale(nil,target,32,32,1,1)
    trcs["songname"].setRGBA(255,255,255,uint8(4*i+15))
    trcs["songname"].put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["levelLabel"].setRGBA(255,255,255,uint8(4*i+15))
    trcs["levelLabel"].put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    score.setRGBA(255,255,255,uint8(4*i+15))
    score.put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    target.flip()
    delay(16)
  while true:
    var event:Event
    doAssert waitEvent(event.addr)==1
    case event.kind
    of KEYDOWN:return mrQuit
    of FINGERDOWN:
      if event.tfinger.x<scrnWidth/2:
        return mrRestart
      else:
        return mrQuit
    of MOUSEBUTTONDOWN:
      if event.button.x<scrnWidth/2:
        return mrRestart
      else:
        return mrQuit
    of QUIT:system.quit()
    else:discard
      