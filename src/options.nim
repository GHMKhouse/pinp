import os
import iniplus
setCurrentDir(getAppDir().parentDir())
var
  options=parseFile("config/options.ini")
proc getOption*(section,key:string):ConfigValue=
  options.getValue(section,key)