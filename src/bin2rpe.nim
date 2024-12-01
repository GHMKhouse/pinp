import std/[json,math,os]
import globals,types,loadbin
proc t2l(x:float):JsonNode=
  %[
    %(int32(x)),
    %(int32((x-floor(x))*1000)),
    %1000
  ]
proc saveRPE*(c:Chart)=
  var data = %{
    "BPMList" : %[],
    "META" : newJObject(),
    "judgeLineList" : %[]
  }
  data["BPMList"] = %[
    %{
      "bpm" : %60.0,
      "startTime" : %[ %0, %0, %1 ]
    }
  ]
  data["META"] = %{
    "RPEVersion" : %892032,
    "background" : %"58365005.jpg",
    "charter" : %charter,
    "composer" : %composer,
    "id" : %"58365005",
    "level" : %level,
    "name" : %title,
    "offset" : %(int(c.offset*1000)),
    "song" : %"58365005.mp3"
  }
  for line in c.lines:
    var jline = %{
      "Group" : %0,
      "Name" : %"Untitled",
      "Texture" : %"line.png",
      "bpmfactor" : %1.0,
      "eventLayers" : %[
        %{
          "alphaEvents" : %[],
          "moveXEvents" : %[],
          "moveYEvents" : %[],
          "rotateEvents" : %[],
          "speedEvents" : %[]
        }
      ],
      "isCover" : %1,
      "notes" : %[],
      "numOfNotes" : %(line.n.len),
      "zOrder" : %0
    }
    for e in line.xe.s:
      jline["eventLayers"][0]["moveXEvents"].add %{
        "easingType" : %1,
        "end" : %(e.v2*1350),
        "endTime" : t2l(e.t2),
        "linkgroup" : %0,
        "start" : %(e.v1*1350),
        "startTime" : t2l(e.t1)
      }
    for e in line.ye.s:
      jline["eventLayers"][0]["moveYEvents"].add %{
        "easingType" : %1,
        "end" : %(e.v2*900),
        "endTime" : t2l(e.t2),
        "linkgroup" : %0,
        "start" : %(e.v1*900),
        "startTime" : t2l(e.t1)
      }
    for e in line.re.s:
      jline["eventLayers"][0]["rotateEvents"].add %{
        "easingType" : %1,
        "end" : %(-e.v2),
        "endTime" : t2l(e.t2),
        "linkgroup" : %0,
        "start" : %(-e.v1),
        "startTime" : t2l(e.t1)
      }
    for e in line.ae.s:
      jline["eventLayers"][0]["alphaEvents"].add %{
        "easingType" : %1,
        "end" : %((e.v2*255).int),
        "endTime" : t2l(e.t2),
        "linkgroup" : %0,
        "start" : %((e.v1*255).int),
        "startTime" : t2l(e.t1)
      }
    var lv=0.0
    for e in line.fe.s:
      if e.t1==e.t2:continue
      let
        v=(e.v2-e.v1)/(e.t2-e.t1)/1.2
      if abs(v-lv)>0.01:
        jline["eventLayers"][0]["speedEvents"].add %{
          "end" : %v,
          "endTime" : t2l(e.t2),
          "linkgroup" : %0,
          "start" : %v,
          "startTime" : t2l(e.t1)
        }
        lv=v
    for n in line.n:
      jline["notes"].add %{
        "above" : %(int(not n.below)),
        "alpha" : %255,
        "endTime" : t2l(n.t2),
        "isFake" : %(int(not n.real)),
        "positionX" : %(n.x*450),
        "size" : %1.0,
        "speed" : %n.speed,
        "startTime" : t2l(n.t1),
        "type" : %(
          case n.kind.int
          of 0:1
          of 2:2
          of 3:3
          of 1:4
          else:1
          ),
        "visibleTime" : %999999.0,
        "yOffset" : %0.0
      }
    data["judgeLineList"].add jline
  var f=open(r"F:\PhiEdit\Resources\58365005\58365005.json",fmWrite)
  defer:f.close()
  f.write(data)
when isMainModule:
  setCurrentDir(getAppDir().parentDir())
  var c=loadBin(r"F:\Projects\pinp\maps\674bf26c27754e25d7317a40\rawChart.bin")
  saveRPE(c)