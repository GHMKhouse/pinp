# Package

version       = "0.1.0"
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
when defined(useopencv):
  requires "opencv >= 0.1.0"

task android,"":
  exec "nimble build --opt:speed -d:release --app:gui --os:android --cpu:arm"