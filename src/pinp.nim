##                  Pinp Is Not Phigros
##        by InkOfSilicon(Olivana National Library)
## This module is the entry of the program. It hasn't required any
## command-line arguments by now.

import std/[algorithm,math,monotimes,os,random,strutils]
import sdl2_nim/[sdl, sdl_ttf, sdl_image, sdl_gpu, sdl_mixer]
import iniplus
when defined(useopencv): # Who has the dlls qwq
  import opencv/[core,highgui,imgproc]

import chartproc,events,globals,loadbin,offical2bin,tools,types

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
    window.setWindowTitle("PINP".cstring)
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
      song="sample321"
      info=parseFile("rsc"/song/"info.ini")                     # Why .ini?
      illustInfo=info.getValue("META","illust").stringVal
      musicInfo=info.getValue("META","music").stringVal
      chartInfo=info.getValue("META","originalChart").stringVal
      title=info.getValue("META","name").stringVal
      level=info.getValue("META","level").stringVal
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
  section readchart:
    if not fileExists("rsc"/song/"rawChart.bin"):
      var f=open("rsc"/song/chartInfo)
      defer:f.close()
      var s:string=newString(64)
      discard f.readChars(toOpenArray(s,0,63))
      if "\"formatVersion\":3" in s:
        tranOffical("rsc"/song/chartInfo)
      elif "\"RPEVersion\"" in s:
        discard
      else:
        raiseAssert("Unsupported format!")
    # benchmark:
    chart=loadBin("rsc"/song/"rawChart.bin")  # used 18ms on my machine
  section prerender:
    var songnameS=font64.renderText_Blended(    # Warning: not DRY
      cstring(title),Color(r:255,g:255,b:255,a:255))
    defer:songnameS.freeSurface
    var songnameI=copyImageFromSurface(songnameS)
    defer:songnameI.freeImage()
    songnameI.setAnchor(0.0,1.0)
    var levelS=font64.renderText_Blended(
      cstring(level),Color(r:255,g:255,b:255,a:255))
    defer:levelS.freeSurface
    var levelI=copyImageFromSurface(levelS)
    defer:levelI.freeImage()
    levelI.setAnchor(1.0,1.0)
    var comboLS=font64.renderText_Blended("PINP",
      Color(r:255,g:255,b:255,a:255))
    defer:comboLS.freeSurface
    var comboLI=copyImageFromSurface(comboLS)
    defer:comboLI.freeImage()
    comboLI.setAnchor(0.5,0.0)
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
          if n.t2<time-0.16 and n.t2>time-0.5 and n.judge==jUnjudged:
            n.judge=jMiss
            combo=0
            inc playResult[jMiss]
            continue
          elif n.t2<=time and n.judge in {jPerfect,jGood,jBad}:continue
          if n.kind==nkHold and n.t1<time-0.16 and n.t2>time-0.5 and n.judge==jUnjudged:
            n.judge=jMiss
            combo=0
            inc playResult[jMiss]
          var
            side:float32=(if n.below: -1 else:1)
            w=n.x*playWidth.toFloat/3*globalScale
            flr=(if n.kind==nkHold or n.t1>time:max(n.f1-f,0) else: n.f1-f)*sizeFactor/noteSize
            nx=w*nc+flr*side*s*100*n.speed*globalScale
            ny=w*ns+flr*side*c*100*n.speed*globalScale
          n.nx=w*nc+(x*globalScale+0.5)*playWidth.toFloat
          n.ny=(0.5-y*globalScale)*scrnHeight.toFloat-w*ns
          n.r=degToRad(h)
          if (n.kind!=nkHold) and
            (nx>playWidth.float or ny>scrnHeight.float):continue
          if autoPlay and n.t2<=time:
            n.judge=(                         # who can make auto-play miss?
              if abs(time-n.t1)<0.08:jPerfect
              elif abs(time-n.t1)<0.16:jGood
              elif abs(time-n.t1)<0.24:jBad
              else:jMiss)
            if n.judge!=jBad and n.judge!=jMiss:
              doSDL:playChannel(channelQ,hitSounds[n.kind],0)
              channelQ=(channelQ+1) mod 64      # 64 channels!
              inc combo
            else:
              combo=0
            hitFXs.add (time,
              float32((x*globalScale+0.5)*playWidth.toFloat+w*nc),
              float32((0.5-y*globalScale)*scrnHeight.toFloat-w*ns),
              radToDeg(n.r),
              n.judge
              )
            inc playResult[n.judge]
          elif n.kind==nkHold and autoPlay and n.t1<time:
            if n.judge==jUnjudged:
              n.judge=(                       # Warning: not DRY
                if abs(time-n.t1)<0.08:jPerfect
                elif abs(time-n.t1)<0.16:jGood
                elif abs(time-n.t1)<0.245:jBad
                else:jMiss)
              if n.judge!=jBad and n.judge!=jMiss:
                doSDL:playChannel(channelQ,hitSounds[n.kind],0)
                channelQ=(channelQ+1) mod 64
                inc combo
              else:
                combo=0
              inc playResult[n.judge]
            let
              now=getMonoTime().ticks()
            if now-n.lastHitFX>100000000:
              hitFXs.add (time,
                float32((x*globalScale+0.5)*playWidth.toFloat+w*nc),
                float32((0.5-y*globalScale)*scrnHeight.toFloat-w*ns),
                radToDeg(n.r),
                n.judge
                )
              n.lastHitFX=now
          if (not autoPlay) and (n.judge notin {jPerfect,jGood,jBad,jMiss}) and n.t1-time<0.24 and (if n.kind==nkHold:time-n.t2<0.24 else:time-n.t1<0.16):
            jNotes.add n
          #if n.t1>time+10:break
          if n.kind==nkHold:
            var u:float32
            if chart.constSpeed:      # const-speed holds
              u=max(n.f1-f,0)+(n.f2-n.f1-n.speed*max(0,time-n.t1))
              nx=w*nc+max(n.f1-f,0)*side*s*100*globalScale*sizeFactor/noteSize
              ny=w*ns+max(n.f1-f,0)*side*c*100*globalScale*sizeFactor/noteSize
              n.nx=nx+(x*globalScale+0.5)*playWidth.toFloat
              n.ny=(0.5-y*globalScale)*scrnHeight.toFloat-ny
            else:
              u=(n.f2-f)*n.speed
            u*=sizeFactor/noteSize
            let
              nex=w*nc+u*side*s*100*globalScale
              ney=w*ns+u*side*c*100*globalScale
            let
              head=tex[if n.hl:Tex.holdHeadHL else:Tex.holdHead]
              body=tex[if n.hl:Tex.holdBodyHL else:Tex.holdBody]
              tail=tex[if n.hl:Tex.holdTailHL else:Tex.holdTail]
            case n.judge
            of jUnjudged:
              body.setRGBA(255,255,255,255)
              tail.setRGBA(255,255,255,255)
              if n.t1>time:
                head.blitTransform(nil,target,
                  n.nx,
                  n.ny,
                  h+90-side*90,0.2*globalScale*sizeFactor,0.2*globalScale*sizeFactor)
              body.blitTransform(nil,target,                     # what's this?
                n.nx+head.h.float/12*sin(r)*side*globalScale*sizeFactor,
                n.ny-head.h.float/12*cos(r)*side*globalScale*sizeFactor,
                h+90-side*90,0.2*globalScale*sizeFactor,
                max(0,n.f2-n.f1-n.speed*max(0,time-n.t1)-0.1)*100/
                  body.h.int.toFloat*globalScale*sizeFactor/noteSize)
            else:
              if n.judge==jMiss or n.judge==jBad:
                body.setRGBA(255,255,255,128)
                tail.setRGBA(255,255,255,128)
              else:
                body.setRGBA(255,255,255,255)
                tail.setRGBA(255,255,255,255)
              body.blitTransform(nil,target,  
                n.nx,
                n.ny,
                h+90-side*90,0.2*globalScale*sizeFactor,
                max(0,n.f2-n.f1-n.speed*max(0,time-n.t1))*100/
                  body.h.int.toFloat*globalScale*sizeFactor/noteSize)
            if u>0:
              tail.blitTransform(nil,
              target,nex+(x*globalScale+0.5)*playWidth.toFloat,
              (0.5-y*globalScale)*scrnHeight.toFloat-ney,
              h+90-side*90,0.2*globalScale*sizeFactor,0.2*globalScale*sizeFactor/noteSize)
            discard
          else:
            let k=case n.kind
            of nkTap:(if n.hl:Tex.tapHL else:Tex.tap)
            of nkDrag:(if n.hl:Tex.dragHL else:Tex.drag)
            of nkFlick:(if n.hl:Tex.flickHL else:Tex.flick)
            else:Tex.holdHead
            if time>n.t1:
              tex[k].setRGBA(255,255,255,uint8(255*(1-min(1,(time-n.t1)*8))))
            else:
              tex[k].setRGBA(255,255,255,255)
            tex[k].blitTransform(nil,target,
              (x*globalScale+0.5)*playWidth.toFloat+nx,
              (0.5-y*globalScale)*scrnHeight.toFloat-ny,
              h+90-side*90,0.2*globalScale*sizeFactor,0.2*globalScale*sizeFactor)
            # if n.t2>time:
            #   tex[k].setRGBA(0,255,0,128)
            #   tex[k].blitTransform(nil,target,
            #     n.nx,
            #     n.ny,
            #     n.r.radToDeg,0.2*globalScale*sizeFactor,0.2*globalScale)
      jNotes.sort((
        proc(x,y:Note):int=
          result=cmp(x.t1,y.t1)
          if abs(result)<1:
            result=cmp(nk2order[x.kind],nk2order[y.kind])
        ),Ascending)
      for id,click in clicks.mpairs:
        var bestJudged:Note=nil
        for n in jNotes:
          if n.judge!=jUnjudged:continue
          var judgedOn=false
          if abs(n.r mod PI)<0.01:
            judgedOn=abs(n.nx-click.x)<150
          elif abs((n.r+PI/2) mod PI)<0.01:
            judgedOn=abs(n.ny-click.y)<150
          else:
            let
              t  = tan(n.r)
              c  = cos(n.r)
              s  = sin(n.r)
              dx = click.x-n.nx
              dy = n.ny-click.y
              ux = (dx*c-dy*s)/(c+s*t)
              uy = -t*ux
            judgedOn=sqrt(ux*ux+uy*uy)<150
          if judgedOn:
            case n.kind
            of nkFlick:
              click.noEarly=true
            of nkDrag:
              if abs(time-n.t1)<0.16:
                n.judge=jHoldingPerfect
              click.noEarly=true
            else:
              if click.noEarly and time-n.t1>0.08:
                click.noEarly=false
                continue
              let j=(if abs(time-n.t1)<0.08:jPerfect
              elif abs(time-n.t1)<0.16:jGood
              elif time>n.t1:jBad
              else:jMiss)
              if n.kind==nkHold and j==jBad:continue
              if bestJudged.isNil:
                bestJudged=n
                n.judge=j
              elif bestJudged.judge<j:
                bestJudged.judge=jUnjudged
                bestJudged=n
                n.judge=j
              if n.kind==nkHold:
                if j==jPerfect:
                  n.judge=jHoldingPerfect
                else:
                  n.judge=jHoldingGood
                
              if j==jPerfect or j==jHoldingPerfect:break
              else:continue
        if (not bestJudged.isNil):
          case bestJudged.kind
          of nkHold:
            doSDL:playChannel(channelQ,hitSounds[bestJudged.kind],0)
            channelQ=(channelQ+1) mod 64
            hitFXs.add (time,
              bestJudged.nx,
              bestJudged.ny,
              radToDeg(bestJudged.r),
              bestJudged.judge
              )
            let now=getMonoTime().ticks()
            bestJudged.lastHitFX=now
            bestJudged.lastHold=now
          else:
            discard

      for id,touch in touchs.mpairs:
        for n in jNotes:
          if n.judge in {jPerfect,jGood,jBad,jMiss}:continue
          var judgedOn=false
          if abs(n.r)<0.01:
            judgedOn=abs(n.nx-touch.x)<150
          elif abs((n.r+PI/2) mod PI)<0.01:
            judgedOn=abs(n.ny-touch.y)<150
          else:
            let
              t  = tan(n.r)
              c  = cos(n.r)
              s  = sin(n.r)
              dx = touch.x-n.nx
              dy = n.ny-touch.y
              ux = (dx*c-dy*s)/(c+s*t)
              uy = -t*ux
            judgedOn=sqrt(ux*ux+uy*uy)<150
          if judgedOn:
            case n.kind
            of nkDrag:
              if abs(time-n.t1)<0.16:
                n.judge=jHoldingPerfect
            of nkHold:
              if n.judge in {jHoldingPerfect,jHoldingGood}:
                let
                  now=getMonoTime().ticks()
                n.lastHold=now
                if now-n.lastHitFX>100000000:
                  hitFXs.add (time,
                    n.nx,
                    n.ny,
                    radToDeg(n.r),
                    n.judge
                    )
                  n.lastHitFX=now
            else:discard
      for id,flick in flicks.mpairs:
        for n in jNotes:
          if n.judge!=jUnjudged or n.kind!=nkFlick:continue
          var judgedOn=false
          if abs(n.r)<0.01:
            judgedOn=abs(n.nx-flick.x)<150
          elif abs((n.r+PI/2) mod PI)<0.01:
            judgedOn=abs(n.ny-flick.y)<150
          else:
            let
              t  = tan(n.r)
              c  = cos(n.r)
              s  = sin(n.r)
              dx = flick.x-n.nx
              dy = n.ny-flick.y
              ux = (dx*c-dy*s)/(c+s*t)
              uy = -t*ux
            judgedOn=sqrt(ux*ux+uy*uy)<150
          if judgedOn:
              if abs(time-n.t1)<0.16:
                n.judge=jHoldingPerfect
      for i in 0..<jNotes.len:
        var n=jNotes[i]
        case n.judge
        of jPerfect,jGood:
          doSDL:playChannel(channelQ,hitSounds[n.kind],0)
          channelQ=(channelQ+1) mod 64
          inc combo
          hitFXs.add (time,
            n.nx,
            n.ny,
            radToDeg(n.r),
            n.judge
            )
          inc playResult[n.judge]
        of jBad:
          combo=0
          inc playResult[n.judge]
          hitFXs.add (time,
            n.nx,
            n.ny,
            radToDeg(n.r),
            n.judge
            )
        of jMiss:
          combo=0
          inc playResult[n.judge]
        of jHoldingPerfect,jHoldingGood:
          if n.kind==nkHold:
            if time+0.24>n.t2:
              n.judge=(if n.judge==jHoldingPerfect:jPerfect else:jGood)
              inc combo
              hitFXs.add (time,
                n.nx,
                n.ny,
                radToDeg(n.r),
                n.judge
                )
              inc playResult[n.judge]
            let now=getMonoTime().ticks
            if now-n.lastHold>200000000:
              n.judge=jBad
              combo=0
              inc playResult[n.judge]
          else:
            if time>=n.t1:
              n.judge=(if n.judge==jHoldingPerfect:jPerfect else:jGood)
              doSDL:playChannel(channelQ,hitSounds[n.kind],0)
              channelQ=(channelQ+1) mod 64
              inc combo
              hitFXs.add (time,
                n.nx,
                n.ny,
                radToDeg(n.r),
                n.judge
                )
              inc playResult[n.judge]
        else:
          discard

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
            x,y,h,1.0*globalScale,1.0*globalScale)
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
      tex[Tex.pause].blitScale(nil,target,32,32,1,1)
      target.rectangleFilled(0,0,
        playWidth.toFloat*time/chart.songLength,8,
        makeColor(255,255,255,128))
      target.rectangleFilled(playWidth.toFloat*time/chart.songLength-2,0,
        playWidth.toFloat*time/chart.songLength+2,8,
        makeColor(255,255,255,255))
      songnameI.blitScale(nil,target,32,scrnHeight.toFloat-32,0.6,0.6)
      levelI.blitScale(nil,target,
        playWidth.toFloat-32,scrnHeight.toFloat-32,0.6,0.6)
      var scoreS=font64.renderText_Blended(
        cstring(align($(int((playResult[jPerfect].float+playResult[jGood]/2)/chart.numOfNotes.float*1000000)),7,'0')),
        Color(r:255,g:255,b:255,a:255))
      defer:scoreS.freeSurface
      var scoreI=copyImageFromSurface(scoreS)
      defer:scoreI.freeImage()
      scoreI.setAnchor(1.0,0.0)
      scoreI.blitScale(nil,target,playWidth.toFloat-32,32,0.8,0.8)
      var fpsS=font64.renderText_Blended(
        cstring($(fps10/10)),Color(r:0,g:255,b:0,a:255))
      defer:fpsS.freeSurface
      var fpsI=copyImageFromSurface(fpsS)
      defer:fpsI.freeImage()
      fpsI.setAnchor(0.0,0.0)
      fpsI.blitScale(nil,target,64,16,0.5,0.5)
      if combo>=3:
        var comboS=font64.renderText_Blended(
          cstring($(int(combo))),Color(r:255,g:255,b:255,a:255))
        defer:comboS.freeSurface
        var comboI=copyImageFromSurface(comboS)
        defer:comboI.freeImage()
        comboI.setAnchor(0.5,1.0)
        comboI.blitScale(nil,target,playWidth.toFloat/2,96,1.2,1.2)
        comboLI.blitScale(nil,target,playWidth.toFloat/2,96,0.4,0.4)
      for id,touch in touchs.pairs:
        target.circleFilled(touch.x,touch.y,10,makeColor(0,255,0,255))
      target.flip()
      
when isMainModule:
  setCurrentDir(getAppDir().parentDir())
  main()
proc NimMain*() {.importc.}