import std/[lenientops,math,oids,options,os]
import sdl2_nim/[sdl, sdl_mixer, sdl_gpu]
import iniplus
import globals,renderutils,tools,types
proc menu* =
  maps.setLen(0)
  var
    i=0
    n=0
  for kind,path in walkDir("maps/"):
    inc n
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
        path,
        path/info.getValue("META","illust").stringVal,
        path/info.getValue("META","music").stringVal
        )
    else:
      discard
    target.clear()
    target.rectangleFilled(64,float32(scrnHeight-256),float32(64+(scrnWidth-128)*(i/n)),float32(scrnHeight-192),white)
    inc i
  crtMap=maps[0]
  const mwidth=384
  var
    menumid=0
    a=0
  doSDL:playChannel(0,crtMap.snd,-1)
  while true:
    target.clear()
    crtMap.bgImg.setRGBA(128,128,128,255)
    crtMap.bgImg.blitScale(nil,target,
      scrnWidth/2,scrnHeight/2,
      scrnWidth.int/crtMap.bgImg.w.int*globalScale,
      scrnHeight.int/crtMap.bgImg.h.int*globalScale)
    crtMap.bgImg.setRGBA(255,255,255,255)
    crtMap.bgImg.blitScale(nil,target,
    scrnWidth/2,scrnHeight/2,
    scrnWidth.int/crtMap.bgImg.w.int*globalScale/2,
    scrnHeight.int/crtMap.bgImg.h.int*globalScale/2)
    for i in 0..15:
      let m=maps[((i+menumid) mod maps.len+maps.len) mod maps.len]
      let ps:array[8,cfloat]=[
        cfloat(-16*i),cfloat(48*i),
        cfloat(-16*i+mwidth+16),cfloat(48*i),
        cfloat(-16*i+mwidth),cfloat(48+48*i),
        cfloat(-16*i-16),cfloat(48+48*i)
      ]
      m.ttitle.setAnchor(1.0,0.0)
      if crtMap==m:
        target.polygonFilled(4,cast[ptr cfloat](ps.addr),makeColor(255,255,255,240))
        m.ttitle.setRGBA(0,0,0,255)
      else:
        target.polygonFilled(4,cast[ptr cfloat](ps.addr),makeColor(128,128,128,128))
        m.ttitle.setRGBA(255,255,255,255)
      m.ttitle.put(target,mwidth-16*i,48*i,0,0.5,0.5)
    template handleEventMenu(ev:Event)=
      case ev.kind
      of QUIT:system.quit()
      of MOUSEBUTTONDOWN:
        if ev.button.x<mwidth+16:
          let i=(int((ev.button.y)/48+menumid+maps.len) mod maps.len + maps.len)mod maps.len
          if crtMap==maps[i]:return
          crtMap=maps[i]
          discard fadeOutChannel(0,500)
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
    menumid=(menumid+a) mod maps.len
    a=sgn(a)*max(0,abs(a)-1)
    if playing(0)==0:
      doSDL:playChannel(0,crtMap.snd,-1)
    var ev:Event
    ev=default(Event)
    doSDL waitEventTimeout(ev.addr,16)
    if ev!=default(Event):
      handleEventMenu(ev)
      while pollEvent(ev.addr)!=0:
        handleEventMenu(ev)
    target.flip()