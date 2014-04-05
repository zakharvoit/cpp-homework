#!/usr/bin/env python

from random import seed, randrange
from sys import argv

MAX_N = 10**int(argv[1])

a = randrange(MAX_N)
b = randrange(MAX_N)

if a < b:
    a, b = b, a

print (a)
print (b)
