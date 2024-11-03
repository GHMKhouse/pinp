import std/[monotimes,oids,options,os]
import sdl2_nim/[sdl, sdl_gpu]
import iniplus
import globals,renderutils,tools,types
proc menu* =
  maps.setLen(0)
  for kind,path in walkDir("rsc/maps/"):
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
  while true:
    target.clear()
    for i,m in maps.pairs():
      m.ttitle.put(target,64,96*i+64,0,1,1)
    template handleEventMenu(ev:Event)=
      case ev.kind
      of QUIT:system.quit()
      of MOUSEBUTTONDOWN:
        for i,m in maps.pairs():
          if ev.button.y>96*i+64 and ev.button.y<96*i+160:
            crtMap=m
            return
      else:discard
    var ev:Event
    ev=default(Event)
    doSDL waitEventTimeout(ev.addr,16)
    if ev!=default(Event):
      handleEventMenu(ev)
      while pollEvent(ev.addr)!=0:
        handleEventMenu(ev)
    target.flip()