#!/usr/bin/env python3
"""Generate a speed table"""

from asmlib import render

def table():
    return \
        [0]*5 + \
        list(range(0,100,10)) + \
        [100]*20 + \
        list(range(100,500,40)) + \
        [500]*19

def main():
    D = table()
    print(len(D))
    print(render(D, unit='dc.w'))

main()
