#!/usr/bin/env python3
import sys
import click
from asmlib import render

# Tables are 64 words long

def fx_1_pic_ratio_sequence():
    return list(range(0,500,8)) + [500]
def fx_2_wave_ratio_sequence():
    return list(range(0,200,6)) + [200]*30
def fx_2_wave_offset_sequence():
    return list(range(0,800,50)) + [800]*16 + list(range(800,100,-22))

@click.command()
@click.argument('name',
                type=click.Choice(["fx_1_pic_ratio_sequence",
                                   "fx_2_wave_ratio_sequence",
                                   "fx_2_wave_offset_sequence"]))
def main(name):
    """Generates a 64 words meta controller table."""
    table = getattr(sys.modules[__name__], name)
    print(render(table(), unit='dc.w'))

if __name__ == '__main__':
    main()
