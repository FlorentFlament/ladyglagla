#!/usr/bin/env python3
"""Generate table with the distances from the previous point on a curve"""

import math
from asmlib import render

def gum_func(x):
    return 10*math.sin(2*math.pi/256 * x)

def gum_table():
    return [80*round(gum_func(x)) for x in range(256)]

def main():
    D = gum_table()
    print(render(D, unit='dc.w'))

main()
