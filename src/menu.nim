import std/[lenientops,math,oids,options,os]
import sdl2_nim/[sdl, sdl_gpu]
import iniplus
import globals,renderutils,tools,types
proc menu* =
  maps.setLen(0)
  for kind,path in walkDir("maps/"):
    case kind
    of pcDir,pcLinkToDir:
      let
        (_,id) = splitPath(path)
        info=parseFile(path/"info.ini")   
      maps.add newMenuMap(
        id.cstring.parseOid(),
        optional(info.getValue("META","name").stringVal).get("Untitled"),
        optional(info.getValue("META","level").stringVal).get("UK  Lv.0"),
        optional(info.getValue("META","composer").stringVal).get("UK"),
        optional(info.getValue("META","charter").stringVal).get("UK"),
        optional(info.getValue("META","illustrator").stringVal).get("UK"),
        path
        )
    else:
      discard
  crtMap=maps[0]
  var
    menumid=0
    a=0
  while true:
    target.clear()
    for i in 0..15:
      let m=maps[(i+menumid+16) mod maps.len]
      let ps:array[8,cfloat]=[
        cfloat(-16*i),cfloat(48*i),
        cfloat(-16*i+528),cfloat(48*i),
        cfloat(-16*i+512),cfloat(48+48*i),
        cfloat(-16*i-16),cfloat(48+48*i)
      ]
      m.ttitle.setAnchor(1.0,0.0)
      if crtMap==m:
        target.polygonFilled(4,cast[ptr cfloat](ps.addr),makeColor(255,255,255,240))
        m.ttitle.setRGBA(0,0,0,255)
      else:
        target.polygonFilled(4,cast[ptr cfloat](ps.addr),makeColor(128,128,128,128))
        m.ttitle.setRGBA(255,255,255,255)
      m.ttitle.put(target,512-16*i,48*i,0,0.5,0.5)
    template handleEventMenu(ev:Event)=
      case ev.kind
      of QUIT:system.quit()
      of MOUSEBUTTONDOWN:
        if ev.button.x<512:
          let i=(int((ev.button.y)/48+maps.len-menumid) mod maps.len)
          crtMap=maps[i]
      of MOUSEMOTION:
        if (getMouseState(nil,nil) and button(BUTTON_LEFT)) > 0:
          if abs(ev.motion.yrel)>20:
            a=ev.tfinger.dy.int div 20
      of MOUSEWHEEL:
        a+=ev.wheel.y
      of FINGERDOWN:
        if abs(ev.tfinger.dy)>20:
          a=ev.tfinger.dy.int div 20
        else:
          let i=(int((ev.button.y)/48+maps.len-menumid) mod maps.len)
          crtMap=maps[i]
      else:discard
    menumid+=a
    a=sgn(a)*max(0,abs(a)-1)
    var ev:Event
    ev=default(Event)
    doSDL waitEventTimeout(ev.addr,16)
    if ev!=default(Event):
      handleEventMenu(ev)
      while pollEvent(ev.addr)!=0:
        handleEventMenu(ev)
    target.flip()