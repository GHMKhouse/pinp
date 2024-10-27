import std/[algorithm,math,monotimes,tables]
import sdl2_nim/[sdl,sdl_mixer]
import globals,tools,types
proc judge* =
  jNotes.sort((
    proc(x,y:Note):int=
      result=cmp(x.t1,y.t1)
      if abs(result)<1:
        result=cmp(nk2order[x.kind],nk2order[y.kind])
    ),Ascending)
  for id,click in clicks.mpairs:
    var
      bestJudged:Note=nil
      early:Note=nil
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
      if judgedOn or click.x==(-1.0):
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
            early=n
            continue
          let j=(if abs(time-n.t1)<0.08:jPerfect
          elif abs(time-n.t1)<0.16:jGood
          elif time<n.t1:jBad
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
    if bestJudged.isNil:
      bestJudged=early
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
      if judgedOn or touch.x==(-1.0):
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
      if judgedOn or flick.x==(-1.0):
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