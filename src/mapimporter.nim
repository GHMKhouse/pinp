import std/[oids,os,streams]
import iniplus,yaml
type
  RPEInfo = ref object
    Name,Path,Song,Picture,Chart,Level,Composer,Charter:string
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
          var info:RPEInfo
          new info
          var f=open(p,fmRead)
          defer:f.close()
          var s=newFileStream(f)
          defer:s.close()
          yaml.load(s,info)
          var ini:ConfigTable
          ini.setKey("META","name",info.Name)
          ini.setKey("META","music",info.Song)
          ini.setKey("META","illust",info.Picture)
          ini.setKey("META","originalChart",info.Chart)
          ini.setKey("META","level",info.Level)
          ini.setKey("META","composer",info.Composer)
          ini.setKey("META","charter",info.Charter)
          ini.setKey("META","illustrator","UK")
          var a=ini.toString()
          var f2=open(d/"info.ini",fmWrite)
          defer:f2.close()
          f2.write(a)
  elif fileExists(path):
    discard
when isMainModule:
  setCurrentDir("D:/czm/pinp/")
  importMap("D:/download/φ҈͢͡ .15")