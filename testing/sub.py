#!/usr/bin/python

from sys import stdin

def diff(s):
    return s[0] - s[1]

print (diff(list(map(int, stdin.read().split()))))

