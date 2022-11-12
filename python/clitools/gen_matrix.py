import sys

width = sys.argv[1]
height = sys.argv[2]

equation = sys.argv[3]

spacing = sys.argv[4] if len(sys.argv) > 4 else " "

code = """
from random import randint


width=%s
height=%s

for i in range(0, height):
    s = ""
    for j in range(0, width):
        a = %s
        s += str(a) + "%s"
    print(s)

""" % (width, height, equation, spacing)
exec(code)
