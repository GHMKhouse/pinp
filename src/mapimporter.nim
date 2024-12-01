import std/[json,oids,os,streams]
import iniplus,yaml/tojson,zip/zipfiles
proc importMap*(path:string)=
  if dirExists(path):
    let
      id=genOid()
      d="maps"/($id)
    createDir(d)
    for k,p in path.walkDir():
      if k==pcFile:
        let
          (_,n,x)=p.splitFile()
        case x
        of ".png",".jpg",".mp3",".ogg",".json","",".ini":
          copyFile(p,d/(n&x))
        of ".txt":
          var f=open(p,fmRead)
          defer:f.close()
          var s=newFileStream(f)
          defer:s.close()
          var j=loadToJson(s)[0]
          var ini:ConfigTable
          ini.setKey("META","name",j["Name"].getStr("UK"))
          ini.setKey("META","music",j["Song"].getStr("UK"))
          ini.setKey("META","illust",j["Picture"].getStr("UK"))
          ini.setKey("META","originalChart",j["Chart"].getStr("UK"))
          ini.setKey("META","level",j["Level"].getStr("UK"))
          ini.setKey("META","composer",j["Composer"].getStr("UK"))
          ini.setKey("META","charter",j["Charter"].getStr("UK"))
          ini.setKey("META","illustrator","UK")
          var a=ini.toString()
          var f2=open(d/"info.ini",fmWrite)
          defer:f2.close()
          f2.write(a)
  elif fileExists(path):
    var z:ZipArchive
    if not z.open(path):
      echo "Unable to open zip file "&path&", exiting."
      quit(QuitFailure)
    let
      t=getTempDir()/"pinp"/"importTemp"
    z.extractAll(t)
    importMap(t)
when isMainModule:
  setCurrentDir(getAppDir().parentDir())
  let args=commandLineParams()
  for a in args:
    importMap(a)