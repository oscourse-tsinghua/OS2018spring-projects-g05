#!/usr/bin/python

import sys, os, tempfile, struct

if len(sys.argv) < 2:
  print 'usage: disasm.py [hex] [hex]...'
  exit(0)

OBJDUMP='mips-sde-elf-objdump'

temp = tempfile.NamedTemporaryFile()
#print temp.name
#temp = open('temp.bin', 'wb')
try:
  for arg in sys.argv[1:]:
    x = int(arg, 16)
    temp.write(struct.pack("I", x))
  
  temp.flush()

  out = os.popen(OBJDUMP+ ' -D -b binary -EL -m mips '+temp.name)
  print out.read()
except:
  print 'Error: invalid input or "'+OBJDUMP+'" not found!'

temp.close()
  #print '%08x' % (x)

