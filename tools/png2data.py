#!/usr/bin/env python3
import sys
from PIL import Image

BLOCK_SIZE = 16 # 16 pixels blocks
BIT_PLANES = 4

def process_block(inblock):
    outblock = [0]*4 # output block consists of 4 16bits words
    for i in range(BLOCK_SIZE):
        for j in range(BIT_PLANES):
            outblock[j] |= ((inblock[i] >> j) & 0x01) << (BLOCK_SIZE-1 - i)
    return outblock

def process_image(data):
    # Isolating blocks of 16 bytes
    blocks = [data[i:i+BLOCK_SIZE] for i in range(0, len(data), BLOCK_SIZE)]
    # Processing blocks and building flatten output
    return [i for b in blocks for i in process_block(b)]

def render(data, perline=8):
    """Renders a array of words to be used by a program."""
    res = []
    for i,v in enumerate(data):
        if i%perline == 0:
            if i != 0:
                res.append('\n')
            res.append('\tdc.w ')
        else:
            res.append(', ')
        res.append("${:04x}".format(v))
    return ''.join(res)

def get_st_palette(rgb_palette):
    st_palette = []
    for c in [rgb_palette[i:i+3] for i in range(0,len(rgb_palette),3)]:
        st_palette.append(((c[0]>>5) << 8) + ((c[1]>>5) << 4) + (c[2]>>5))
    return st_palette

def main():
    fname = sys.argv[1]
    im = Image.open(fname)
    data = list(im.getdata())
    st_pic = process_image(data)
    print("picture:")
    print(render(st_pic))
    print("palette:")
    print(render(get_st_palette(im.getpalette()[:48])))

main()
