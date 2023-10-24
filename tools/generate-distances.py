#!/usr/bin/env python3
"""Generate table with the distances from the previous point on a curve"""

import math
from asmlib import render

def gum_func():
#    return [15*math.sin(2*math.pi/201 * x) + x for x in range(201)]
    return [7*math.sin(4*math.pi/201 * x) + x for x in range(201)]

def gum():
    d = gum_func()
    D = []
    for i in range(200):
        D.append(round(d[i+1] - sum(D[:i])))
    return D

def main():
    D = gum()
    #print(sum(D))
    #print(render([1]*200, unit='dc.b'))
    print(render(D, unit='dc.b'))
    #print(render([1]*200, unit='dc.b'))

main()
