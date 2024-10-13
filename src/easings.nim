import math,macros
type
  Easing* = enum
    easeInstant=0
    easeLinear=1
    easeOutSine=2
    easeInSine=3
    easeOutQuad=4
    easeInQuad=5
    easeInOutSine=6
    easeInOutQuad=7
    easeOutCubic=8
    easeInCubic=9
    easeOutQuart=10
    easeInQuart=11
    easeInOutCubic=12
    easeInOutQuart=13
    easeOutQuint=14
    easeInQuint=15
    easeOutExpo=16
    easeInExpo=17
    easeOutCirc=18
    easeInCirc=19
    easeOutBack=20
    easeInBack=21
    easeInOutCirc=22
    easeInOutBack=23
    easeOutElastic=24
    easeInElastic=25
    easeOutBounce=26
    easeInBounce=27
macro genEase(x):auto=
  x.expectKind nnkStmtList
  result=newTree(nnkBracket)
  for i in x:
    let n=ident("x")
    result.add quote do:
      proc(`n`:float64):float64
        {.noSideEffect,gcSafe,closure.}=`i`
let
  easings*:array[
    Easing,proc(x:float64):float64
    {.noSideEffect,gcSafe,closure.}
    ]=genEase:
    1
    x
    sin(x*PI/2)
    1-cos(x*PI/2)
    1-(1-x)^2
    x^2
    -(cos(x*PI)-1)/2
    if x<0.5:2*x^2 else:1-(-2*x+2)^2/2
    1-(1-x)^3
    x^3
    1-(1-x)^4
    x^4
    if x<0.5:4*x^3 else:1-(-2*x+2)^3/2
    if x<0.5:8*x^4 else:1-(-2*x+2)^4/2
    1-(1-x)^5
    x^5
    if x==1:1 else: 1-pow(2,-10*x)
    if x==0:0 else: pow(2,10*x-10)
    sqrt(1-(x-1)^2)
    1-sqrt(1-x^2)
    1+2.70158*(x-1)^3+1.70158*(x-1)^2
    2.70158*x^3-1.70158*x^2
    if x<0.5:
      (1-sqrt(1-(2*x)^2))/2
    else:
      (sqrt(1-(-2*x+2)^2)+1)/2
    if x<0.5:
      ((2*x)^2*(3.5949095*2*x-2.5949095))/2
    else:
      ((2*x-2)^2*(3.5949095*(x*2-2)+2.5949095)+2)/2
    if x==0:
      0
    elif x==1:
      1
    else:
      pow(2,-10*x)*sin((x*10-0.75)*2*PI/3)+1
    if x==0:
      0
    elif x==1:
      1
    else:
      -pow(2,10*x-10)*sin((x*10-10.75)*2*PI/3)
    if x<0.3636364:
      7.5625*x^2
    elif x<0.7272727:
      7.5625*(x-0.5454545)^2+0.75
    elif x<0.9090909:
      7.5625*(x-0.8181818)^2+0.9375
    else:
      7.5625*(x-0.9545455)^2+0.984375
    1-(if 1-x<0.3636364:
      7.5625*(1-x)^2
    elif 1-x<0.7272727:
      7.5625*(1-x-0.5454545)^2+0.75
    elif 1-x<0.9090909:
      7.5625*(1-x-0.8181818)^2+0.9375
    else:
      7.5625*(1-x-0.9545455)^2+0.984375)
    