#!/usr/bin/env python3
"""Generate an offset table om [-50,50["""

TABLE_LEN=256

import math
from asmlib import render

def sin_func(x):
    return 50*math.sin(2*math.pi/TABLE_LEN * x)

def sin_table():
    return [round(sin_func(x)) for x in range(TABLE_LEN)]

def main():
    D = sin_table()
    print(render(D, unit='dc.w'))

main()
