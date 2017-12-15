#!/usr/bin/python
import sys, os, tempfile, struct

def isjump(line):
  jmp = ['jal', 'j', 'jr', 'b', 'bne','beq',
          'bneg']
  for x in jmp:
    if line.find('\t'+x+'\t') != -1:
      return True
  return False

OBJDUMP='mips-sde-elf-objdump'

if len(sys.argv) < 2:
  print 'usage: check_delay_slot.py [file]'
  exit(0)

print 'checking...'
f = os.popen(OBJDUMP+' -d '+sys.argv[1])
while(True):
  line = f.readline()
  if not line: break
  if isjump(line):
    line1 = f.readline()
    if line1.find('nop')== -1:
      print 'Error: ', line.replace('\n','')
      print '\t->', line1.replace('\n','')
      print ''

ret = f.close()
if ret:
  print 'Error: code=', ret
else:
  print 'Done'
