#!/usr/bin/python

from random import seed, randrange

MAX_N = 10 ** 30

a = randrange(MAX_N)
b = randrange(MAX_N)

if a < b:
    a, b = b, a

print (a)
print (b)
