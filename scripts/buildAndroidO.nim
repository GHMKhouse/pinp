import osproc,json,strutils
var f=parseFile("androidgen/pinp.json")
for c in f["compile"]:
  echo c[0].str," returned: ",execCmd(c[1].str.replace("clang.exe",r"F:\ASDK\ndk\28.0.12433566\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi28-clang.cmd"))