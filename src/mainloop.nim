import std/[lenientops,math,monotimes,options,strutils,tables]
import sdl2_nim/[sdl, sdl_gpu, sdl_mixer]

import chartproc,events,globals,hitfx,judge,
  noteproc,renderutils,tools,types
proc mainLoop*:MainReturn=
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
  var t=lt
  var lct=lt
  var fps:int
  var cnt=0
  while true:
    inc cnt
    t=getMonoTime().ticks()
    if t-lct>=1_000_000_000:
      fps=cnt
      cnt=0
      lct=t
    if t-lt<int(1_000_000_000/maxFPS):
      delay(uint32(int(1_000/maxFPS)-((t-lt) div 1_000_000)))
    lt=t
    time=(int(t-beginEpoch)/1_000_000_000+chart.offset)*speedScale+startTime
    if time>chart.songLength+1.0:
      return mrEnd
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
    for id,c in clicks.pairs:
      if c.x>0 and c.y>0 and c.x<tex[Tex.pause].w+32 and c.y<tex[Tex.pause].h+32:
        discard fadeOutMusic(1000)
        return mrQuit
    judge()
    renderHitFX()
    
    tex[Tex.pause].blitScale(nil,target,32,32,1,1)
    target.rectangleFilled(0,0,
      playWidth.toFloat*time/chart.songLength,8,
      makeColor(255,255,255,128))
    target.rectangleFilled(playWidth.toFloat*time/chart.songLength-2,0,
      playWidth.toFloat*time/chart.songLength+2,8,
      white)
    trcs["songname"].put(target,32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    trcs["levelLabel"].put(target,
      playWidth.toFloat-32,scrnHeight.toFloat-32,0.0,0.6,0.6)
    var score=newTextRenderingCache(align($(int((playResult[jPerfect].float+playResult[jGood]/2)/chart.numOfNotes.float*1000000)),7,'0'),
      white,1.0,0.0)
    score.put(target,playWidth.toFloat-32,32,0.0,0.8,0.8)
    var fpsLabel=newTextRenderingCache($(fps),Color(r:0,g:255,b:0,a:255),0.0,0.0)
    fpsLabel.put(target,64,16,0.0,0.5,0.5)
    if combo>=3:
      var comboNum=newTextRenderingCache($(int(combo)),white,0.5,1.0)
      comboNum.put(target,playWidth.toFloat/2,96,0.0,1.2,1.2)
      trcs["comboLabel"].put(target,playWidth.toFloat/2,96,0.0,0.4,0.4)
    for id,touch in touchs.pairs:
      target.circleFilled(touch.x,touch.y,10,makeColor(0,255,0,255))
    target.flip()
