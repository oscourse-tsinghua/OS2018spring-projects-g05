#!/usr/bin/env python3

import os
import shutil

TEMPLATE_DIR = 'template/'
SRC_DIR = 'tests/'
OUT_DIR = 'output/'

with open(TEMPLATE_DIR + 'template.vhd') as f:
    template = f.read();

for testCase in os.listdir(SRC_DIR):
    out = template.replace("{{{TEST_NAME}}}", testCase)
    with open(OUT_DIR + testCase + '.vhd', 'w') as outFile:
        outFile.write(out)

shutil.copyfile(TEMPLATE_DIR + 'fake_ram.vhd', OUT_DIR + 'fake_ram.vhd')
shutil.copyfile(TEMPLATE_DIR + 'test_const.vhd', OUT_DIR + 'test_const.vhd')

