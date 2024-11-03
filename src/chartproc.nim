import types
proc readEvent*(events:TIter[LEvent],t:float32):float32=
  if events.len!=0:
    var
      e:LEvent
      le:LEvent=events[0]
    for i in events.i..<events.len-1:
      e=events[i+1]
      if t<le.t2:return le.v1+(le.v2-le.v1)*(t-le.t1)/(le.t2-le.t1)
      elif t<e.t1:return le.v2
      elif t<e.t2:return e.v1+(e.v2-e.v1)*(t-e.t1)/(e.t2-e.t1)
      le=e
    return le.v2