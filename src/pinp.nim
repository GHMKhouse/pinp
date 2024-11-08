##                  Pinp Is Not Phigros
##        by InkOfSilicon(Olivana National Library)
## This module is the entry of the program. It hasn't required any
## command-line arguments by now.

import std/[os,strutils]
import sdl2_nim/[sdl, sdl_ttf, sdl_image, sdl_gpu, sdl_mixer]
import iniplus
when defined(useopencv): # Who has the dlls qwq
  import opencv/[core,highgui,imgproc]

import globals,loadingscreen,mainloop,menu,over,tools,types

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
  var state=0
  while true:
    case state
    of 0:
      menu()
      state=1
    of 1:
      loadChart()
      state=2
    of 2:
      case mainloop()
      of mrEnd:
        state=3
      of mrQuit:
        state=0
      of mrRestart:
        state=1
    of 3:
      case over()
      of mrQuit:
        state=0
      of mrRestart:
        state=1
      of mrEnd:
        break
    else:
      break

when isMainModule:
  setCurrentDir(getAppDir().parentDir())
  main()
proc NimMain*() {.importc.}