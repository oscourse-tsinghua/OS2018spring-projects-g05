#!/usr/bin/env python3

import os
import errno
import itertools
import optparse
import sys

# Require mipsel-linux-gnu installed in PATH
# If you are using other tool chain, change this
XCOMPILER = 'mipsel-linux-gnu'

TEMPLATE_DIR = 'template/'
parser = optparse.OptionParser()
parser.add_option('-i', '--in',  action='store', type='string', dest='src_dir', default='tests',
        help='directory in which source files lie')
parser.add_option('-o', '--out', action='store', type='string', dest='out_dir', default='output',
        help='directory in which output testcases be put; each testcase a subdirectory')
parser.add_option('-c', '--case', action='store', type='string', dest='case',
        help='test case name')
options, _ = parser.parse_args(sys.argv)

src_dir = options.src_dir + '/'
out_dir = options.out_dir + '/'

''' Compile assembly into hexadecimal VHDL literal '''
def genHexInst(s):
    print("[DEBUG] assembling %s"%(s))
    with open('.tmp.s', 'w') as f:
        f.write(s + '\n')
    if os.system('%s-as -mips32 .tmp.s -o .tmp.o 2>&1 | awk \'{print "as: " $0}\''%(XCOMPILER)):
        raise Exception("Assembling failed")
    if os.system('%s-objcopy -j .text -O binary .tmp.o .tmp.bin 2>&1 | awk \'{print "objcopy: " $0}\''%(XCOMPILER)):
        raise Exception("Assembling failed")
    with open('.tmp.bin', 'rb') as f:
        hexStr = '_'.join(map(lambda byte: '%02x'%(byte), f.read(4)))
        return 'x"%s"'%(hexStr)

''' Generate the VHDL statements for {{{INIT_INST_RAM}}} '''
def genInitInstRam(runCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    for i, cmd in zip(itertools.count(), runCmd):
        stmts.append('words(%d) <= %s; -- RUN %s'%(i + 1, genHexInst(cmd), cmd))
    return '\n'.join(stmts)

''' Generate the VHDL statements for {{{ASSERTIONS}}} '''
def genAssertions(assertCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    for period, lhs, rhs in assertCmd:
        stmts.append('process begin')
        stmts.append('    wait for CLK_PERIOD; -- resetting')
        stmts.append('    wait for %s * CLK_PERIOD;'%(period))
        stmts.append('    assert user_%s = %s severity FAILURE;'%(lhs, rhs))
        stmts.append('    wait;')
        stmts.append('end process;')
    return '\n'.join(stmts)

''' Generate the VHDL statements for {{{ALIASES}}} '''
def genAliases(defineCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    for alias, hierarchy in defineCmd:
        stmts.append('alias user_%s is <<signal ^.cpu1_ist.datapath_ist.%s>>;'%(alias, hierarchy))
    return '\n'.join(stmts)

def genAliasesCPU2(defineCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    for alias, hierarchy in defineCmd:
        stmts.append('alias user_%s is <<signal ^.cpu2_ist.datapath_ist.%s>>;'%(alias, hierarchy))
    return '\n'.join(stmts)

def genImports(importCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    for package in importCmd:
        stmts.append('use work.%s.all;' % package)
    return '\n'.join(stmts)

def genConfigs(configCmd):
    stmts = ['-- CODE BELOW IS AUTOMATICALLY GENERATED']
    pairs = {'CPU2_ON': 0, 'ENABLE_CACHE': 0}
    for item in configCmd:
        if item.upper() in pairs:
            pairs[item.upper()] = 1
        else:
            raise Exception("Unrecognized config '%s'"%(item))
    for key in pairs:
        stmts.append("constant %s: std_logic := '%d';"%(key, pairs[key]))
    return '\n'.join(stmts)

''' Parse test file and return (RUN instructions, ASSERT (period #,signal,literal), DEFINE (alias,reference) '''
def parse(filename):
    runCmd = []
    assertCmd = []
    defineCmd = []
    defineCPU2Cmd = []
    importCmd = []
    configCmd = []
    with open(src_dir + filename) as f:
        for line in f:
            line = line.rstrip()
            if line.split() == []:
                continue
            if line[0] == '#':
                continue
            op, param = line.split(None, 1)
            if op == 'RUN':
                runCmd.append(param)
            elif op == 'ASSERT':
                assertCmd.append(param.split(None, 2))
            elif op == 'DEFINE':
                defineCmd.append(param.split(None, 1))
            elif op == 'DEFINE_CPU2':
                defineCPU2Cmd.append(param.split(None, 1))
            elif op == 'IMPORT':
                importCmd.append(param)
            elif op == 'CONFIG':
                configCmd.append(param)
            else:
                raise Exception("Unrecognized op '%s'"%(op))
    return (runCmd, assertCmd, defineCmd, defineCPU2Cmd, importCmd, configCmd)

templateNames = ['tb.vhd', 'fake_ram.vhd', 'test_const.vhd']
templates = {}

for name in templateNames:
    with open(TEMPLATE_DIR + name) as f:
        templates[name] = f.read();

def generate(testCase):
    if testCase[0] == '.': # Might be editor temporary files
        return
    runCmd, assertCmd, defineCmd, defineCPU2Cmd, importCmd, configCmd = parse(testCase)
    initInstRam = genInitInstRam(runCmd)
    assertions = genAssertions(assertCmd)
    aliases = genAliases(defineCmd) + '\n' + genAliasesCPU2(defineCPU2Cmd)
    imports = genImports(importCmd)
    configs = genConfigs(configCmd)

    try:
        os.makedirs(out_dir + testCase)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise

    for name in templateNames:
        out = templates[name]
        out = out.replace("{{{NOTICE}}}", "-- DO NOT MODIFY THIS FILE.\n-- This file is generated by hard_tests_gen")
        out = out.replace("{{{TEST_NAME}}}", testCase)
        out = out.replace("{{{INIT_INST_RAM}}}", initInstRam)
        out = out.replace("{{{ASSERTIONS}}}", assertions)
        out = out.replace("{{{ALIASES}}}", aliases)
        out = out.replace("{{{IMPORT}}}", imports)
        out = out.replace("{{{CONFIGS}}}", configs)
        outputName = name if name != 'template.vhd' else testCase + '.vhd'
        with open("%s/%s/%s"%(out_dir, testCase, "%s_%s"%(testCase, outputName)), 'w') as outFile:
            outFile.write(out)

if options.case:
    generate(options.case)
else:
    for testCase in os.listdir(src_dir):
        generate(testCase)

