# have done nothing by now
import loadbin,savebin,types
# proc lEvent(t1,t2:float32,v1,v2:float64):LEvent=
#   LEvent(t1:t1,t2:t2,v1:v1,v2:v2)
# proc optimize(l:TIter[LEvent]):TIter[LEvent]=
#   if l.len<2:return l
#   result=toTIter(newSeqOfCap[LEvent](l.len))
#   var
#     t1=l[0].t1
#     t2=l[0].t2
#     v1=l[0].v1
#     v2=l[0].v2
#     k1=(v2-v1)/(t2-t1)
#   for e in l.s:
#     if abs(e.t1-t2)>0.00001 or
#       (e.v2-e.v1)/(e.t2-e.t1)*k1<0 or
#       abs((e.v2-e.v1)/(e.t2-e.t1)-k1)>0.0001:
#         result.add lEvent(t1,t2,v1,v2)
#         t1=e.t1
#         t2=e.t2
#         v1=e.v1
#         v2=e.v2
#         k1=(v2-v1)/(t2-t1)
#     else:
#       t2=e.t2
#       v2=e.v2
#       k1=(v2-v1)/(t2-t1)
#   result.add lEvent(t1,t2,v1,v2)

proc optimize(c:Chart):Chart=
  new result
  result.constSpeed=c.constSpeed
  result.offset=c.offset
  result.songLength=c.songLength
  result.numOfNotes=c.numOfNotes
  for line in c.lines:
    var l:JLine
    new l
    l.xe=line.xe
    l.ye=line.ye
    l.re=line.re
    l.ae=line.ae
    l.fe=line.fe
    l.n=line.n
    result.lines.add l
proc optimize*(path:string)=
  var c=loadBin(path)
  var o=optimize(c)
  savebin(path,o)