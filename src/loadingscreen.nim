import std/[monotimes,os,strutils,tables]
import sdl2_nim/[sdl,sdl_gpu,sdl_mixer]
import iniplus
import globals,loadbin,offical2bin,options,renderutils,rpe2bin,tools,types
proc loadBasic(progress:uint8)=
  target.clear()
  bg.setRGBA(128,128,128,255)
  bg.blitScale(nil,target,
    scrnWidth/2,scrnHeight/2,
    scrnWidth.int/bg.w.int*globalScale,
    scrnHeight.int/bg.h.int*globalScale)
  gui["loadingbg_up"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(progress/255),scrnWidth.float32,scrnHeight.float32)
  gui["loadingbg_down"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(2-progress/255),scrnWidth.float32,scrnHeight.float32)
  bg.setRGBA(255,255,255,progress)
  bg.blitScale(nil,target,
    scrnWidth/2,scrnHeight/2,
    scrnWidth.int/bg.w.int*globalScale/2,
    scrnHeight.int/bg.h.int*globalScale/2)

proc loadIntro* =
  doSDL:playChannel(0,snds["loadingIntro"],0)
  for i in 0..20:
    let progress=uint8(i*12+15)
    loadBasic(progress)
    tex[Tex.pause].setRGBA(255,255,255,progress)
    tex[Tex.pause].blitScale(nil,target,32,32,1,1)
    trcs["songname"].setRGBA(255,255,255,progress)
    trcs["songname"].put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["levelLabel"].setRGBA(255,255,255,progress)
    trcs["levelLabel"].put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["scoreLabel"].setRGBA(255,255,255,progress)
    trcs["scoreLabel"].put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    trcs["composerLabel"].setRGBA(255,255,255,progress)
    trcs["composerLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-64,0.0,0.4,0.4)
    trcs["charterLabel"].setRGBA(255,255,255,progress)
    trcs["charterLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-96,0.0,0.4,0.4)
    trcs["illustratorLabel"].setRGBA(255,255,255,progress)
    trcs["illustratorLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-128,0.0,0.4,0.4)
    target.flip()
    delay(16)
proc loadOutro*(dt:int64) =
  if loadingDelay==(-1):
    while true:
      var event:Event
      doAssert waitEvent(event.addr)==1
      if event.kind in {KEYDOWN,FINGERDOWN,MOUSEBUTTONDOWN}:
        break
      elif event.kind==QUIT:system.quit()
  else:
    delay(loadingDelay.uint32)
  doSDL:playChannel(0,snds["loadingOutro"],0)
  for i in 0..60:
    let progress=uint8(255-4*i)
    loadBasic(progress)
    tex[Tex.pause].blitScale(nil,target,32,32,1,1)
    trcs["songname"].put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["levelLabel"].put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["scoreLabel"].put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    trcs["composerLabel"].setRGBA(255,255,255,progress)
    trcs["composerLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-64,0.0,0.4,0.4)
    trcs["charterLabel"].setRGBA(255,255,255,progress)
    trcs["charterLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-96,0.0,0.4,0.4)
    trcs["illustratorLabel"].setRGBA(255,255,255,progress)
    trcs["illustratorLabel"].put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-128,0.0,0.4,0.4)
    target.flip()
    delay(uint32(max(0,16-(dt div 1000000))))
  bg.setRGBA(255,255,255,128)
proc loadChart* =
  var st=getMonoTime().ticks()
  for ch in freeingChunks:
    freeChunk(ch)
  freeingChunks.setLen(0)
  section initLevel:
    info=parseFile(crtMap.path/"info.ini")                     # Why .ini?
    illustInfo=info.getValue("META","illust").stringVal
    musicInfo=info.getValue("META","music").stringVal
    chartInfo=info.getValue("META","originalChart").stringVal
    title=crtMap.title
    level=crtMap.level
    composer=crtMap.composer
    charter=crtMap.charter
    illustrator=crtMap.illustrator
    if not bg.isNil:
      bg.freeImage()
    when defined(useopencv):                                    # help
      if not fileExists(crtMap.path/"illustBlur.png"):
        var
          cvim=highgui.loadImage(crtMap.path/illustInfo,1)
          blurim=createImage(
            TSize(width:cvim.width,height:cvim.height),
            DEPTH_MAX,3)
        smooth(cvim,blurim)
        discard saveImage(crtMap.path/"illustBlur.png",blurim,nil)
      bg=sdl_gpu.loadImage(crtMap.path/"illustBlur.png")
    else:
      bg=sdl_gpu.loadImage(cstring(crtMap.path/illustInfo))
    assert not bg.isNil()
    bg.setAnchor(0.5,0.5)
    bg.setRGB(128,128,128)
    music=loadMUS(cstring(crtMap.path/musicInfo))
    trcs["songname"]=newTextRenderingCache(title,white,0.0,1.0)
    trcs["levelLabel"]=newTextRenderingCache(level,white,1.0,1.0)
    trcs["comboLabel"]=newTextRenderingCache("PINP",white,0.5,0.0)
    trcs["composerLabel"]=newTextRenderingCache("composer:"&composer,white,0.5,1.0)
    trcs["charterLabel"]=newTextRenderingCache("charter:"&charter,white,0.5,1.0)
    trcs["illustratorLabel"]=newTextRenderingCache("illustrator:"&illustrator,white,0.5,1.0)
    trcs["scoreLabel"]=newTextRenderingCache("0000000",white,1.0,0.0)
    snds["loadingIntro"]=loadWAV("rsc/snd/loadintro.ogg")
    snds["loadingOutro"]=loadWAV("rsc/snd/loadoutro.ogg")
    snds["over"]=loadWAV("rsc/snd/over.ogg")
  loadIntro()
  section readchart:
    if getOption("DEBUG","alwaysReload").intVal.bool or not fileExists(crtMap.path/"rawChart.bin"):
      var f=open(crtMap.path/chartInfo)
      defer:f.close()
      var s=f.readAll()
      if "\"formatVersion\":3" in s:
        tranOffical(crtMap.path/chartInfo)
      elif "\"RPEVersion\"" in s:
        tranRPE(crtMap.path/chartInfo)
      else:
        raiseAssert("Unsupported format!")
    # benchmark:
    chart=loadBin(crtMap.path/"rawChart.bin")  # used 18ms on my machine
  playResult=[0,0,0,0,0,0,0]
  clicks.clear()
  flicks.clear()
  touchs.clear()
  keyInputs.clear()
  jNotes.setLen(0)
  hitFXs.setLen(0)
  combo=0
  loadOutro(getMonoTime().ticks()-st)