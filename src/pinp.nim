##                  Pinp Is Not Phigros
##        by InkOfSilicon(Olivana National Library)
## This module is the entry of the program. It hasn't required any
## command-line arguments by now.
## It also deals with general rendering tasks.

import std/[math,monotimes,options,os,strutils]
import sdl2_nim/[sdl, sdl_ttf, sdl_image, sdl_gpu, sdl_mixer]
import iniplus
when defined(useopencv): # Who has the dlls qwq
  import opencv/[core,highgui,imgproc]

import chartproc,events,globals,hitfx,judge,loadbin,
  noteproc,offical2bin,options,renderutils,rpe2bin,tools,types

proc main=
  section initSDL: # `section` does nothing, but it's easier to read
    doSDL sdl.init(INIT_EVERYTHING)
    defer: sdl.quit()
    doSDL sdl_ttf.init()
    defer: sdl_ttf.quit()
    doSDL sdl_image.init(INIT_EVERYTHING)
    defer: sdl_image.quit()
    doSDL initSubSystem(INIT_EVERYTHING)
    defer: quitSubSystem(INIT_EVERYTHING)
    doSDL sdl_mixer.init(INIT_MP3 or INIT_OGG)
    defer: sdl_mixer.quit()
    doSDL sdl_mixer.openAudio(
      DEFAULT_FREQUENCY,
      DEFAULT_FORMAT,
      8,
      512
    )
    doAssert sdl_mixer.allocateChannels(64)==64
  section initWindowTarget:
    window = createWindow("".cstring
      , WINDOWPOS_CENTERED, WINDOWPOS_CENTERED,
      scrnWidth.cint, scrnHeight.cint,
      WINDOW_SHOWN.uint8 or WINDOW_OPENGL # or WINDOW_BORDERLESS
    )
    setInitWindow(window.getWindowID())
    window.getWindowMaximumSize(maxWidth.addr, maxHeight.addr)
    target = sdl_gpu.init(maxWidth.uint16, maxHeight.uint16, INIT_EVERYTHING)
    defer: sdl_gpu.quit()
    setDefaultAnchor(0.0, 0.0)
    setEventFilter(
      proc(data: pointer, event: ptr sdl.Event): cint{.cdecl.} =
      if event.kind in {QUIT, MOUSEBUTTONDOWN, MOUSEBUTTONUP, MOUSEWHEEL,
          MOUSEMOTION,FINGERDOWN,FINGERUP,FINGERMOTION,
          KEYDOWN, KEYUP, TEXTEDITING, TEXTINPUT}: 1 else: 0,
      nil
    )
    stopTextInput()
    window.setWindowTitle("PINP".cstring)
    discard eventState(EventKind.SENSORUPDATE,IGNORE) # not a good idea
  section initRes:
    font16 = openFont("rsc/font.ttf".cstring, 16) # not DRY, waiting for fix
    font16.setFontKerning(0)
    font16.setFontOutline(0)
    font32.setFontHinting(0)
    font32 = openFont("rsc/font.ttf".cstring, 32)
    font32.setFontKerning(0)
    font32.setFontOutline(0)
    font32.setFontHinting(0)
    font64 = openFont("rsc/font.ttf".cstring, 64)
    font32.setFontKerning(0)
    font32.setFontOutline(0)
    font32.setFontHinting(0)
    hitSounds[nkFlick]=loadWAV("rsc/snd/HitSong2.ogg")
    for kind, path in os.walkDir("rsc/gui/"):
      if kind == pcFile:
        let (_, n, x) = splitFile(path)
        if x == ".png" or x == ".jpg":
          gui[n]=loadImage(path.cstring)
          case n
          of "loadingbg_up","loadingbg_down":
            gui[n].setAnchor(0.5,0.5)
    hitSounds[nkTap]=loadWAV("rsc/snd/HitSong0.ogg") # from lchzh3473
    hitSounds[nkHold]=hitSounds[nkTap]
    hitSounds[nkDrag]=loadWAV("rsc/snd/HitSong1.ogg")
    hitSounds[nkFlick]=loadWAV("rsc/snd/HitSong2.ogg")
    for kind, path in os.walkDir("rsc/tex/"):     # maybe not a good idea, waiting for fix
      if kind == pcFile:
        let (_, n, x) = splitFile(path)
        try:
          let e:Tex=parseEnum[Tex](n)
          if x == ".png" or x == ".jpg":
            tex[e] = loadImage(path.cstring)
            case e
            of Tex.line, tap, tapHL, drag, dragHL, flick, flickHL,
                holdHead, holdHeadHL, holdTail, holdTailHL, hitFX:
              tex[e].setAnchor(0.5, 0.5)
            of holdBody, holdBodyHL:
              tex[e].setAnchor(0.5, 1.0)
            else:discard
        except ValueError:
          continue
    let
      song=getOption("DEBUG","song").stringVal
      info=parseFile("rsc"/song/"info.ini")                     # Why .ini?
      illustInfo=info.getValue("META","illust").stringVal
      musicInfo=info.getValue("META","music").stringVal
      chartInfo=info.getValue("META","originalChart").stringVal
      title=optional(info.getValue("META","name").stringVal).get("Untitled")
      level=optional(info.getValue("META","level").stringVal).get("UK  Lv.0")
      composer=optional(info.getValue("META","composer").stringVal).get("UK")
      charter=optional(info.getValue("META","charter").stringVal).get("UK")
      illustrator=optional(info.getValue("META","illustrator").stringVal).get("UK")
    when defined(useopencv):                                    # help
      if not fileExists("rsc"/song/"illustBlur.png"):
        var
          cvim=highgui.loadImage("rsc"/song/illustInfo,1)
          blurim=createImage(
            TSize(width:cvim.width,height:cvim.height),
            DEPTH_MAX,3)
        smooth(cvim,blurim)
        discard saveImage("rsc"/song/"illustBlur.png",blurim,nil)
      bg=sdl_gpu.loadImage("rsc"/song/"illustBlur.png")
    else:
      bg=sdl_gpu.loadImage(cstring("rsc"/song/illustInfo))
    assert not bg.isNil()
    defer:bg.freeImage()
    bg.setAnchor(0.5,0.5)
    bg.setRGB(128,128,128)
    music=loadMUS(cstring("rsc"/song/musicInfo))
  section prerender:
    var
      songname=newTextRenderingCache(title,white,0.0,1.0)
      levelLabel=newTextRenderingCache(level,white,1.0,1.0)
      comboLabel=newTextRenderingCache("PINP",white,0.5,0.0)
      composerLabel=newTextRenderingCache("composer:"&composer,white,0.5,1.0)
      charterLabel=newTextRenderingCache("charter:"&charter,white,0.5,1.0)
      illustratorLabel=newTextRenderingCache("illustrator:"&illustrator,white,0.5,1.0)
      scoreLabel=newTextRenderingCache("0000000",white,1.0,0.0)
  var
    loadingIntro=loadWAV("rsc/snd/loadintro.ogg")
    loadingOutro=loadWAV("rsc/snd/loadoutro.ogg")
  doSDL:playChannel(0,loadingIntro,0)
  for i in 0..20:
    target.clear()
    bg.setRGBA(128,128,128,255)
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale,
      scrnHeight.int/bg.h.int*globalScale)
    gui["loadingbg_up"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(i/20),scrnWidth.float32,scrnHeight.float32)
    gui["loadingbg_down"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(2-i/20),scrnWidth.float32,scrnHeight.float32)
    bg.setRGBA(255,255,255,uint8(12*i+15))
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale/2,
      scrnHeight.int/bg.h.int*globalScale/2)
    tex[Tex.pause].setRGBA(255,255,255,uint8(12*i+15))
    tex[Tex.pause].blitScale(nil,target,32,32,1,1)
    songname.setRGBA(255,255,255,uint8(12*i+15))
    songname.put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    levelLabel.setRGBA(255,255,255,uint8(12*i+15))
    levelLabel.put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    scoreLabel.setRGBA(255,255,255,uint8(12*i+15))
    scoreLabel.put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    composerLabel.setRGBA(255,255,255,uint8(12*i+15))
    composerLabel.put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-64,0.0,0.4,0.4)
    charterLabel.setRGBA(255,255,255,uint8(12*i+15))
    charterLabel.put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-96,0.0,0.4,0.4)
    illustratorLabel.setRGBA(255,255,255,uint8(12*i+15))
    illustratorLabel.put(target,scrnWidth.toFloat/2,scrnHeight.toFloat-128,0.0,0.4,0.4)
    target.flip()
    delay(16)
  section readchart:
    if getOption("DEBUG","alwaysReload").intVal.bool or not fileExists("rsc"/song/"rawChart.bin"):
      var f=open("rsc"/song/chartInfo)
      defer:f.close()
      var s:string=newString(256)
      discard f.readChars(toOpenArray(s,0,255))
      if "\"formatVersion\":3" in s:
        tranOffical("rsc"/song/chartInfo)
      elif "\"RPEVersion\"" in s:
        tranRPE("rsc"/song/chartInfo)
      else:
        raiseAssert("Unsupported format!")
    # benchmark:
    chart=loadBin("rsc"/song/"rawChart.bin")  # used 18ms on my machine
  var loadingDelay=getOption("DEBUG","loadingDelay").intVal
  if loadingDelay==(-1):
    while true:
      var event:Event
      doAssert waitEvent(event.addr)==1
      if event.kind in {KEYDOWN,FINGERDOWN,MOUSEBUTTONDOWN}:
        break
  else:
    delay(loadingDelay.uint32)
  doSDL:playChannel(0,loadingOutro,0)
  for i in 0..60:
    target.clear()
    bg.setRGBA(128,128,128,255)
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale,
      scrnHeight.int/bg.h.int*globalScale)
    gui["loadingbg_up"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(1-i/60),scrnWidth.float32,scrnHeight.float32)
    gui["loadingbg_down"].blitScale(nil,target,scrnWidth/2,scrnHeight/2*(1+i/60),scrnWidth.float32,scrnHeight.float32)
    bg.setRGBA(255,255,255,uint8(255-4*i))
    bg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/bg.w.int*globalScale/2,
      scrnHeight.int/bg.h.int*globalScale/2)
    target.flip()
    delay(16)
  bg.setRGBA(255,255,255,128)
  # delay 10000 # easier to open obs to record
  section mainLoop:
    globals.playing=true
    doSDL sdl_mixer.openAudio(
      int(DEFAULT_FREQUENCY*speedScale),
      DEFAULT_FORMAT,
      8,
      int(512*speedScale)
    )
    doAssert sdl_mixer.allocateChannels(64)==64
    let v=volumeMusic(-1)
    discard volumeMusic(int(v.toFloat))
    doSDL playMusic(music,1)
    rewindMusic()
    discard setMusicPosition(startTime.float64)
    var lt=getMonoTime().ticks()  # in nanoseconds!
    beginEpoch=lt.int
    var t=lt                    # terrible naming, waiting for fix
    var fps10:int
    var lc=lt
    var ll=lt
    while true:
      t=getMonoTime().ticks()
      time=(int(t-beginEpoch)/1_000_000_000+chart.offset)*speedScale+startTime
      if time>chart.songLength+1.0:
        break
      if t-lc>=1_000_000_000:
        fps10=int(10_000_000_000/int(t-ll))
        lc=t
      ll=t
      # if t-lt<16000000:
      #   delay(uint32(16-((t-lt) shr 20)))
      #   lt=t
      clicks.clear()
      flicks.clear()
      var ev:Event
      if globals.playing:
        while pollEvent(ev.addr)!=0:
          handleEvent(ev)
      else:
        ev=default(Event)
        doSDL waitEventTimeout(ev.addr,16)
        if ev!=default(Event):
          handleEvent(ev)
          while pollEvent(ev.addr)!=0:
            handleEvent(ev)
      target.clear()
      bg.blitScale(nil,target,
        scrnWidth/2,scrnHeight/2,
        scrnWidth.int/bg.w.int*globalScale,
        scrnHeight.int/bg.h.int*globalScale)
      jNotes.setLen(0)
      for l in chart.lines:
        let
          x=readEvent(l.xe,time)
          y=readEvent(l.ye,time)
          h= -readEvent(l.re,time)
          r= degToRad(h)
          a=readEvent(l.ae,time)
          s=sin(r)                  # huh?
          ns=sin(-r)
          c=cos(r)
          nc=cos(-r)
          f=readEvent(l.fe,time)
        let
          (cr,cg,cb)=(
            if playResult[jBad]+playResult[jMiss]>0:(255'u8,255'u8,255'u8)
            elif playResult[jGood]>0:(180,225,255)
            else:(237'u8,236'u8,176'u8)
            )
        tex[Tex.line].setRGBA(cr,cg,cb,
          max(a*255,minLineAlpha).toInt.uint8)
        tex[Tex.line].blitTransform(nil,target,
          (x*globalScale+0.5)*playWidth.toFloat,
          (0.5-y*globalScale)*scrnHeight.toFloat,h,
          2.0,2.0*globalScale)                      # width or height events?
        for n in l.n:
          if n.kind==nkHold:
            n.update((x,y,h,r,a,s,ns,c,nc,f))
        for n in l.n:
          if n.kind!=nkHold:
            n.update((x,y,h,r,a,s,ns,c,nc,f))
      judge()
      renderHitFX()
      
      tex[Tex.pause].blitScale(nil,target,32,32,1,1)
      target.rectangleFilled(0,0,
        playWidth.toFloat*time/chart.songLength,8,
        makeColor(255,255,255,128))
      target.rectangleFilled(playWidth.toFloat*time/chart.songLength-2,0,
        playWidth.toFloat*time/chart.songLength+2,8,
        white)
      songname.put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
      levelLabel.put(target,
        playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
      var score=newTextRenderingCache(align($(int((playResult[jPerfect].float+playResult[jGood]/2)/chart.numOfNotes.float*1000000)),7,'0'),
        white,1.0,0.0)
      score.put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
      var fpsLabel=newTextRenderingCache($(fps10/10),Color(r:0,g:255,b:0,a:255),0.0,0.0)
      fpsLabel.put(target,64,16,0.0,0.5,0.5)
      if combo>=3:
        var comboNum=newTextRenderingCache($(int(combo)),white,0.5,1.0)
        comboNum.put(target,playWidth.toFloat/2,96,0.0,1.2,1.2)
        comboLabel.put(target,playWidth.toFloat/2,96,0.0,0.4,0.4)
      for id,touch in touchs.pairs:
        target.circleFilled(touch.x,touch.y,10,makeColor(0,255,0,255))
      target.flip()
  var score=newTextRenderingCache(
    align($(int((playResult[jPerfect].float+playResult[jGood]/2)/chart.numOfNotes.float*1000000)),7,'0'),
    white,1.0,0.0)
  var
    over=loadWAV("rsc/snd/over.ogg")
  doSDL:playChannel(0,over,-1)
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
    songname.setRGBA(255,255,255,uint8(4*i+15))
    songname.put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    levelLabel.setRGBA(255,255,255,uint8(4*i+15))
    levelLabel.put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    score.setRGBA(255,255,255,uint8(4*i+15))
    score.put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    target.flip()
    delay(16)
  while true:
    var event:Event
    doAssert waitEvent(event.addr)==1
    if event.kind in {KEYDOWN,FINGERDOWN,MOUSEBUTTONDOWN}:
      break
when isMainModule:
  setCurrentDir(getAppDir().parentDir())
  main()
proc NimMain*() {.importc.}