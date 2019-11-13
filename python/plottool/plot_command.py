from random import randint

import matplotlib
matplotlib.use('TkAgg')

import matplotlib.pylab as pylab
import subprocess
import time
import sys
import os

ibash_exe = "/usr/local/bin/interactive_bash"

if not os.path.exists(ibash_exe):
    ibash_create_cmd = "echo '#!/bin/bash' >> " + ibash_exe + \
        " &&    echo '/bin/bash -i \"$@\"' >> " \
        + ibash_exe + " && chmod +x " + ibash_exe
    print(ibash_create_cmd)
    ibash_create_output = subprocess.check_output(ibash_create_cmd, shell=True)
    ibash_create_output = ibash_create_output.strip()
    print(ibash_create_output)

max_seconds = int(sys.argv[2])

subprocess_cmd = sys.argv[1]

time_values = []
command_outputs = []

now = time.time()
later = time.time()
difference = int(later - now)

while (time.time() - now) < max_seconds:
    time_values.append(float((time.time() - now)))

    subprocess_output = subprocess.check_output(subprocess_cmd, shell=True, executable=ibash_exe)
    subprocess_output = subprocess_output.decode("utf8")
    subprocess_output = subprocess_output.strip()

    command_outputs.append(float(subprocess_output))

colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 'tab:pink', 'tab:gray', 'tab:olive', 'tab:cyan', "xkcd:crimson", "xkcd:lavender"]
pylab.plot(time_values, command_outputs, '-o', color=colors[randint(0, len(colors) - 1)])
pylab.show()
