#!/usr/bin/python

from sys import stdin

def product(s):
    return s[0] * s[1]

print (product(list(map(int, stdin.read().split()))))

