#!/usr/bin/env python3
"""Generate a speed table"""

from asmlib import render

def table():
    return \
        list(range(50,800,10)) + \
        list(range(800,400,-10)) + \
        [400]*13

def main():
    D = table()
    print(render(D, unit='dc.w'))

main()
