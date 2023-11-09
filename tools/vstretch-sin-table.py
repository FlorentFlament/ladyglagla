#!/usr/bin/env python3
"""Generate a vertical stretch sinus table"""

TABLE_LEN=256

import math
from asmlib import render


def sin_func(x):
    return 75*math.sin(2*math.pi/TABLE_LEN * x) + 125

def sin_table():
    return [round(sin_func(x)) for x in range(TABLE_LEN)]

def main():
    D = sin_table()
    print(render(D, unit='dc.w'))

main()
