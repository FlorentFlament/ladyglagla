#!/usr/bin/env python3
import os
import argparse
from PIL import Image
from asmlib import render

BLOCK_SIZE = 16 # 16 pixels blocks

def process_block(inblock, bitplanes):
    """
    bitplanes determines the number of colors: 2**bitplanes
    """
    outblock = [0]*bitplanes # output block consists of bitplanes 16bits words
    for i in range(BLOCK_SIZE):
        for j in range(bitplanes):
            outblock[j] |= ((inblock[i] >> j) & 0x01) << (BLOCK_SIZE-1 - i)
    return outblock

def process_image(data, bitplanes):
    """
    bitplanes determines the number of colors: 2**bitplanes
    """
    # Isolating blocks of 16 bytes
    blocks = [data[i:i+BLOCK_SIZE] for i in range(0, len(data), BLOCK_SIZE)]
    # Processing blocks and building flatten output
    return [i for b in blocks for i in process_block(b, bitplanes)]

def get_st_palette(rgb_palette):
    st_palette = []
    for c in [rgb_palette[i:i+3] for i in range(0,len(rgb_palette),3)]:
        st_palette.append(((c[0]>>5) << 8) + ((c[1]>>5) << 4) + (c[2]>>5))
    return st_palette

def pretty_name(filepath):
    name = "_".join(os.path.basename(filepath).split(sep=".")[:-1])
    name.replace("-", "_")
    return name

def main():
    parser = argparse.ArgumentParser(
        prog='png2data',
        description='Converts a PNG image into Atari ST assembly data')
    parser.add_argument('filename')
    parser.add_argument('-b', '--bitplanes', help='bitplanes count', type=int, choices=range(1,5), default=4)

    args = parser.parse_args()
    im = Image.open(args.filename)
    data = list(im.getdata())
    st_pic = process_image(data, args.bitplanes)

    name = pretty_name(args.filename)
    print()
    print(f"{name}:")
    print(f"{name}_palette:")
    print(render(get_st_palette(im.getpalette()[:48])))
    print(f"{name}_data:")
    print(render(st_pic))

main()
