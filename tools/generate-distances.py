#!/usr/bin/env python3
"""Generate table with the distances from the previous point on a curve"""

import math
from asmlib import render

def distances(f):
    """
    f is a table of f(n) for n 0 -> ...
    returns a table of distances between n+1 and n (for 0 <= n < len(f))
    """
    return [math.sqrt( (f[n+1]-f[n])**2 + 1 ) for n in range(len(f)-1)]

def main():
#    d = distances([20*math.sin(x/10) for x in range(201)])
#    d = [(x/201)**2*200 for x in range(201)]
    d = [30*math.sin(2*math.pi/201 * x) + x for x in range(201)]
    print(d)

    D = []
    for i in range(200):
        #        D.append(round(sum(d[:i+1]) - sum(D[:i])))
        D.append(round(d[i+1] - sum(D[:i])))

    print(sum(D))
    print(render([1]*200, unit='dc.b'))
    print(render(D, unit='dc.b'))
    print(render([1]*200, unit='dc.b'))

main()
