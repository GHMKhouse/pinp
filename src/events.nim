import std/[tables]
import sdl2_nim/[sdl]
import globals,types
proc handleEvent*(event:Event)=
  case event.kind
  of QUIT:quit(QuitSuccess)
  of FINGERDOWN,MOUSEBUTTONDOWN,KEYDOWN:
    var
      tx,ty:cfloat
      id:TouchID
    case event.kind
    of MOUSEBUTTONDOWN:
      var x,y:cint
      discard getMouseState(x.addr,y.addr)
      tx=x.toFloat
      ty=y.toFloat
      id=MOUSE_TOUCHID
    of KEYDOWN:
      if event.key.repeat==0:
        tx=(-1.0)
        ty=(-1.0)
        id=(event.key.keysym.scancode.int)
        clicks[id]=Touch(time:time,x:tx,y:ty,noEarly:false)
        touchs[id]=Touch(time:time,x:tx,y:ty,parentClick:clicks[id].addr)
        flicks[id]=Touch(time:time,x:tx,y:ty,parentClick:clicks[id].addr)
      return
    else:
      tx=event.tfinger.x
      ty=event.tfinger.y
      id=event.tfinger.touchId

    clicks[id]=Touch(time:time,x:tx,y:ty,noEarly:false)
    touchs[id]=Touch(time:time,x:tx,y:ty,parentClick:clicks[id].addr)
  of FINGERUP,MOUSEBUTTONUP,KEYUP:
    var
      id:TouchID
    case event.kind
    of MOUSEBUTTONUP:
      id=MOUSE_TOUCHID
    of KEYUP:
      id=(event.key.keysym.scancode.int)
    else:
      id=event.tfinger.touchId
    touchs.del(id)
  of FINGERMOTION,MOUSEMOTION:
    var
      tx,ty,dx,dy:cfloat
      id:TouchID
    case event.kind
    of MOUSEMOTION:
      tx=event.motion.x.toFloat
      ty=event.motion.y.toFloat
      dx=event.motion.xrel.toFloat
      dy=event.motion.yrel.toFloat
      id=MOUSE_TOUCHID
    else:
      tx=event.tfinger.x
      ty=event.tfinger.y
      dx=event.tfinger.dx
      dy=event.tfinger.dy
      id=event.tfinger.touchId
    if dx*dx+dy*dy>1024:
      flicks[id]=Touch(time:time,x:tx,y:ty,parentClick:(if id in clicks:clicks[id].addr else:nil))
    if id!=MOUSE_TOUCHID:
      if id notin touchs:
        touchs[id]=Touch(time:time,x:tx,y:ty,parentClick:nil)
      touchs[id].x=tx
      touchs[id].y=ty
    elif id in touchs:
      touchs[id].x=tx
      touchs[id].y=ty
  else:discard