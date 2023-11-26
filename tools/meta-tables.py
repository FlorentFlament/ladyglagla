#!/usr/bin/env python3
import sys
import click
from asmlib import render

# Tables are 64 words long

def fx_1_pic_ratio_sequence():
    return list(range(50,500,8)) + [500]*7
def fx_2_wave_ratio_sequence():
    return list(range(0,200,6)) + [200]*30
def fx_2_wave_offset_sequence():
    return list(range(0,800,50)) + [800]*16 + list(range(800,100,-22))
def fx_3_pic_offset_sequence():
    return [0]*5 + list(range(0,150,8)) + [150]*40
def fx_3_pic_ratio_sequence():
    return [400]*32 + list(range(400,50,-12)) + [50]*2
def fx_4_pic_offset_sequence():
    return list(range(0,-(80*16),-80)) + [-80*16]*32
def fx_4_pic_ratio_sequence():
    return [0]*5 + [100]*10 + [0]*25 + [40]*24
def fx_4_wave_offset_sequence():
    return [800]*20 + list(range(800,100,-70)) + [100]*5 + list(range(100,800,70)) + [800]*19
def fx_4_wave_ratio_sequence():
    return [200]*30 + list(range(200,50,-15)) + [50]*24

@click.command()
@click.argument('name',
                type=click.Choice([
                    "fx_1_pic_ratio_sequence",
                    "fx_2_wave_ratio_sequence",
                    "fx_2_wave_offset_sequence",
                    "fx_3_pic_offset_sequence",
                    "fx_3_pic_ratio_sequence",
                    "fx_4_pic_ratio_sequence",
                    "fx_4_wave_offset_sequence",
                    "fx_4_wave_ratio_sequence",
                    "fx_4_pic_offset_sequence",
                ]))
def main(name):
    """Generates a 64 words meta controller table."""
    table = getattr(sys.modules[__name__], name)
    print(f"{name}:")
    print(render(table(), unit='dc.w'))

if __name__ == '__main__':
    main()
