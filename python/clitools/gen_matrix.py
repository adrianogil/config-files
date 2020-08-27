import sys

width = sys.argv[1]
height = sys.argv[2]

equation = sys.argv[3]

code = """
from random import randint


width=%s
height=%s

for i in range(0, height):
    s = ""
    for j in range(0, width):
        a = %s
        s += str(a) + " "
    print(s)

""" % (width, height, equation)
exec(code)
