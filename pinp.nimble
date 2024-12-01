# Package

version       = "0.1.2"
author        = "Olivana National Library"
description   = "Pinp Is Not Phigros"
license       = "MIT"
srcDir        = "src"
bin           = @["pinp"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"
requires "sdl2_nim >= 2.0.0"
requires "iniplus >= 0.3.0"
requires "yaml >= 2.1.1"
requires "zip >= 0.3.1"
when defined(useopencv):
  requires "opencv >= 0.1.0"

task android,"rm ./android":
  if exists("androidgen"):
    exec "rm androidgen"
  exec "nimble build --opt:speed -d:release -c --cpu:arm --os:android -d:androidNDK --noMain:on --nimcache:$projectdir/../androidgen --verbose"
  exec "nim c -r scripts/buildAndroidO.nim -o bin/buildAndroidO.exe"