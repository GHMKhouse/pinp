import std/[math,monotimes]
import sdl2_nim/[sdl,sdl_gpu,sdl_mixer]
import globals,tools,types
proc update*(n:Note,lineData:(float32,float32,float32,float32,float32,float32,float32,float32,float32,float32))=
  let (x,y,h,r,_,s,ns,c,nc,f)=lineData
  if autoPlay and n.kind!=nkHold and n.judge==jUnjudged and n.t2<=time:
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
      float32((x*globalScale+0.5)*playWidth.toFloat+n.x*playWidth.toFloat/3*globalScale*nc),
      float32((0.5-y*globalScale)*scrnHeight.toFloat-n.x*playWidth.toFloat/3*globalScale*ns),
      radToDeg(n.r),
      n.judge
      )
    inc playResult[n.judge]
  if n.t2<time-0.16 and n.t2>time-0.5 and n.judge==jUnjudged:
    n.judge=jMiss
    combo=0
    inc playResult[jMiss]
    return
  elif n.t2<=time and n.judge in {jPerfect,jGood,jBad}:return
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
  if (n.kind!=nkHold) and f-n.f1>1.0:return
  n.nx=w*nc+(x*globalScale+0.5)*playWidth.toFloat+flr*side*s*100*n.speed*globalScale
  n.ny=(0.5-y*globalScale)*scrnHeight.toFloat-w*ns-flr*side*c*100*n.speed*globalScale
  n.r=degToRad(h)
  if (n.kind!=nkHold) and
    (nx>playWidth.float or ny>scrnHeight.float):return
  if autoPlay and n.t2<=time:
    if n.judge==jHoldingPerfect or n.judge==jHoldingGood:
      n.judge=(if n.judge==jHoldingPerfect:jPerfect else:jGood)
      inc combo
      inc playResult[n.judge]
    elif n.judge==jUnjudged:
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
  if n.kind==nkHold and autoPlay and n.t1<time:
    if n.t2<time+0.24:
      if n.judge==jHoldingPerfect or n.judge==jHoldingGood:
        n.judge=(if n.judge==jHoldingPerfect:jPerfect else:jGood)
        inc combo
        inc playResult[n.judge]
    if n.judge==jUnjudged:
      n.judge=(                       # Warning: not DRY
        if abs(time-n.t1)<0.08:jHoldingPerfect
        elif abs(time-n.t1)<0.16:jHoldingGood
        elif abs(time-n.t1)<0.245:jBad
        else:jMiss)
      if n.judge==jBad or n.judge==jMiss:
        combo=0
        inc playResult[n.judge]
      else:
        doSDL:playChannel(channelQ,hitSounds[n.kind],0)
        channelQ=(channelQ+1) mod 64
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
    var
      u,v:float32
    if chart.constSpeed:      # const-speed holds
      u=max(n.f1-f,0)+(n.f2-n.f1-n.speed*max(0,time-n.t1))
      v=n.f2-n.f1-n.speed*max(0,time-n.t1)
      nx=w*nc+max(n.f1-f,0)*side*s*100*globalScale*sizeFactor/noteSize*(if n.judge==jUnjudged:1 else:0)
      ny=w*ns+max(n.f1-f,0)*side*c*100*globalScale*sizeFactor/noteSize*(if n.judge==jUnjudged:1 else:0)
      n.nx=nx+(x*globalScale+0.5)*playWidth.toFloat
      n.ny=(0.5-y*globalScale)*scrnHeight.toFloat-ny
    else:
      u=(n.f2-f)*n.speed
      v=n.f2-max(n.f1,f)
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
        max(0,v-0.1)*100/
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
        max(0,v)*100/
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
    if n.judge!=jBad:
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
