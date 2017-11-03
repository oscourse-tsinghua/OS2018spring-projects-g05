import ctypes
import sys

imm_to_signed_extend = [
    'addi', 'addiu', 'slti', 'sltiu'
]

imm_to_unsigned_extend = [
    'andi', 'ori', 'xori'
]

single_period = [
    'and', 'andi', 'or', 'ori', 'xor', 'xori', 'nor', 'lui',
    'sll', 'sllv', 'srl', 'sra', 'srlv', 'srav', 'nop',
    'mfhi', 'mflo', 'mthi', 'mtlo', 'movn', 'movz',
    'add', 'addu', 'sub', 'subu', 'slt', 'sltu',
    'addi', 'addiu', 'slti', 'sltiu', 'clo', 'clz', 'multu', 'mult', 'mul',
    'jr', 'jalr', 'j', 'jal',
    'b', 'bal', 'beq', 'bgez', 'bgezal', 'bgtz', 'blez', 'bltz', 'bltzal', 'bne'
]

two_periods = [
    'madd', 'maddu', 'msub', 'msubu'
]

write_to_simple_reg = [
    'and', 'andi', 'or', 'ori', 'xor', 'xori', 'nor', 'lui',
    'sll', 'sllv', 'srl', 'sra', 'srlv', 'srav',
    'mfhi', 'mflo', 'movn', 'movz',
    'add', 'addu', 'sub', 'subu', 'slt', 'sltu',
    'addi', 'addiu', 'slti', 'sltiu', 'clo', 'clz', 'mul'
]

write_to_hi_lo = [
    'mthi', 'mtlo', 'multu', 'mult',
    'madd', 'maddu', 'msub', 'msubu'
]

jump = [
    'jr', 'jalr', 'j', 'jal'
]
branch = [
    'b', 'bal', 'beq', 'bgez', 'bgezal', 'bgtz', 'blez', 'bltz', 'bltzal', 'bne'
]

insts = [None]
reg = [0] * 32
hi, lo = (0, 0)
memory = dict()
now_period = 5
is_delay_slot = False
j_b_dest = None
pc = 1

def finish_one(periods_inc, dest_type, pos=0):
    global now_period
    now_period += periods_inc
    if dest_type == 'reg':
        assert_object = 'reg(%d)' % pos
        if pos == 0:
            reg[pos] = 0
        assert_value = reg[pos]
    if dest_type == 'hi':
        assert_object = 'hi'
        assert_value = hi
    if dest_type == 'lo':
        assert_object = 'lo'
        assert_value = lo
    if dest_type != 'none':
        print 'ASSERT %d %s 32ux"%x"' % (now_period, assert_object, assert_value)

class Instruct():
    def __init__(self, s, order):
        self.order = order,
        'mfhi', 'mflo',
        'mfhi', 'mflo',
        'mfhi', 'mflo'
        if s.strip() == 'nop':
            self.opcode, self.operands = 'nop', []
        else:
            self.opcode, self.operands = s.strip().split(' ', 1)
            self.operands = self.operands.strip().split(',')

            def _proc_operands(s):
                s = s.strip()
                if s.startswith('$'):
                    return int(s[1:])
                else:
                    x = int(s, 16)
                    if self.opcode in imm_to_signed_extend:
                        x = self._extend(x, True, 16)
                    elif self.opcode in imm_to_unsigned_extend:
                        x = self._extend(x, False, 16)
                    return x
            self.operands = list(map(_proc_operands, self.operands))

    def execute(self):
        global pc, hi, lo, j_b_dest
        pc += 1
        success_j_b = False
        #print self.opcode, self.operands

        if self.opcode == 'ori':
            reg[self.operands[0]] = reg[self.operands[1]] | self.operands[2]
        if self.opcode == 'andi':
            reg[self.operands[0]] = reg[self.operands[1]] & self.operands[2]
        if self.opcode == 'xori':
            reg[self.operands[0]] = reg[self.operands[1]] ^ self.operands[2]
        if self.opcode == 'or':
            reg[self.operands[0]] = reg[self.operands[1]] | reg[self.operands[2]]
        if self.opcode == 'and':
            reg[self.operands[0]] = reg[self.operands[1]] & reg[self.operands[2]]
        if self.opcode == 'xor':
            reg[self.operands[0]] = reg[self.operands[1]] ^ reg[self.operands[2]]
        if self.opcode == 'nor':
            tmp = reg[self.operands[1]] | reg[self.operands[2]]
            reg[self.operands[0]] = tmp ^ int('f' * 8, 16)
        if self.opcode == 'lui':
            reg[self.operands[0]] = reg[self.operands[0]] | (self.operands[1] << 16)
        if self.opcode == 'sll':
            reg[self.operands[0]] = self._cut(reg[self.operands[1]] << self.operands[2])
        if self.opcode == 'sllv':
            reg[self.operands[0]] = self._cut(reg[self.operands[1]] << (reg[self.operands[2]] & 31))
        if self.opcode == 'srl':
            reg[self.operands[0]] = self._shift_right(reg[self.operands[1]], self.operands[2])
        if self.opcode == 'srlv':
            reg[self.operands[0]] = self._shift_right(reg[self.operands[1]], reg[self.operands[2]] & 31)
        if self.opcode == 'sra':
            reg[self.operands[0]] = self._shift_right(reg[self.operands[1]], self.operands[2], True)
        if self.opcode == 'srav':
            reg[self.operands[0]] = self._shift_right(reg[self.operands[1]], reg[self.operands[2]] & 31, True)
        if self.opcode == 'mfhi':
            reg[self.operands[0]] = hi
        if self.opcode == 'mflo':
            reg[self.operands[0]] = lo
        if self.opcode == 'mthi':
            hi = reg[self.operands[0]]
        if self.opcode == 'mtlo':
            lo = reg[self.operands[0]]
        if self.opcode == 'movn':
            if reg[self.operands[2]] != 0:
                reg[self.operands[0]] = reg[self.operands[1]]
        if self.opcode == 'movz':
            if reg[self.operands[2]] == 0:
                reg[self.operands[0]] = reg[self.operands[1]]
        if (self.opcode == 'add' or self.opcode == 'addu' or
            self.opcode == 'sub' or self.opcode == 'subu' or
            self.opcode == 'addi' or self.opcode == 'addiu'):
            x = reg[self.operands[1]]
            if 'i' in self.opcode:
                y = self.operands[2]
            else:
                y = reg[self.operands[2]]
            if self.opcode.startswith('sub'):
                y = self._complement(y)
            res = self._cut(x + y)
            if self.opcode.endswith('u') or not self._add_overflow(x, y, res):
                reg[self.operands[0]] = res
        if (self.opcode == 'slt' or self.opcode == 'sltu' or
            self.opcode == 'slti' or self.opcode == 'sltiu'):
            x = reg[self.operands[1]]
            if 'i' in self.opcode:
                y = self.operands[2]
            else:
                y = reg[self.operands[2]]
            if self.opcode.endswith('u'):
                lt = x < y
            else:
                lt = (x < y and x >> 31 == y >> 31) or (x >> 31 > y >> 31)
            if lt:
                reg[self.operands[0]] = 1
            else:
                reg[self.operands[0]] = 0
        if self.opcode == 'clo' or self.opcode == 'clz':
            if self.opcode == 'clo':
                b = 1
            else:
                b = 0
            res = 0
            while res < 32 and (reg[self.operands[1]] >> (31 - res)) & 1 == b:
                res += 1
            reg[self.operands[0]] = res
        if (self.opcode == 'multu' or self.opcode == 'mult' or self.opcode == 'mul' or
            self.opcode == 'madd' or self.opcode == 'maddu' or self.opcode == 'msub' or self.opcode == 'msubu'):
            if self.opcode == 'mul':
                x, y = reg[self.operands[1]], reg[self.operands[2]]
            else:
                x, y = reg[self.operands[0]], reg[self.operands[1]]
            product = self._multiply(x, y, not self.opcode.endswith('u'))
            if self.opcode == 'mul':
                reg[self.operands[0]] = self._cut(product)
            elif self.opcode == 'multu' or self.opcode == 'mult':
                hi, lo = product >> 32, self._cut(product)
            else:
                hilo = (hi << 32) + lo
                if 'sub' in self.opcode:
                    product = self._complement(product, 64)
                hilo = self._cut(hilo + product, 64)
                hi, lo = hilo >> 32, self._cut(hilo)
        if self.opcode in jump or self.opcode in branch:
            if self.opcode in jump:
                success_j_b = True
                if self.opcode.endswith('r'):
                    j_b_dest = reg[self.operands[-1]] >> 2
                else:
                    j_b_dest = self.operands[0] >> 2
            else:
                success_j_b = True
                if 'eq' in self.opcode:
                    success_j_b = reg[self.operands[0]] == reg[self.operands[1]]
                if 'ne' in self.opcode:
                    success_j_b = reg[self.operands[0]] != reg[self.operands[1]]
                if 'gez' in self.opcode:
                    success_j_b = reg[self.operands[0]] >> 31 == 0
                if 'gtz' in self.opcode:
                    success_j_b = (reg[self.operands[0]] != 0 and reg[self.operands[0]] >> 31 == 0)
                if 'lez' in self.opcode:
                    success_j_b = (reg[self.operands[0]] == 0 or reg[self.operands[0]] >> 31 == 1)
                if 'ltz' in self.opcode:
                    success_j_b = reg[self.operands[0]] >> 31 == 1
                if success_j_b:
                    j_b_dest = pc + (self.operands[-1] >> 2)
            if success_j_b and 'al' in self.opcode:
                ret_addr = (pc + 1) << 2
                if self.opcode == 'jalr' and len(self.operands) == 2:
                    reg[self.operands[0]] = ret_addr
                else:
                    reg[31] = ret_addr

        if self.opcode in single_period:
            periods_inc = 1
        elif self.opcode in two_periods:
            periods_inc = 2

        if self.opcode == 'nop':
            finish_one(1, 'none')
        elif self.opcode in write_to_simple_reg:
            finish_one(periods_inc, 'reg', self.operands[0])
        elif self.opcode in write_to_hi_lo:
            finish_one(periods_inc, 'hi')
            finish_one(0, 'lo')
        elif self.opcode in jump or self.opcode in branch:
            if self.opcode == 'jalr' and len(self.operands) == 2:
                finish_one(periods_inc, 'reg', self.operands[0])
            else:
                finish_one(periods_inc, 'reg', 31)

        global is_delay_slot
        if success_j_b:
            is_delay_slot = True
        else:
            if is_delay_slot == True:
                pc = j_b_dest
            is_delay_slot = False


    @staticmethod
    def _cut(x, bits=32):
        return x & ((1 << bits) - 1)

    @staticmethod
    def _complement(x, bits=32):
        return Instruct._cut((x ^ ((1 << bits) - 1)) + 1, bits)

    @staticmethod
    def _add_overflow(x, y, res, bits=32):
        slb = bits - 1
        return (((x >> slb) == 0 and (y >> slb) == 0 and (res >> slb) == 1) or
                ((x >> slb) == 1 and (y >> slb) == 1 and (res >> slb) == 0))


    @staticmethod
    def _extend(x, signed, origin_bits=16):
        if signed:
            if origin_bits == 8:
                real_val = ctypes.c_int8(x).value
            elif origin_bits == 16:
                real_val = ctypes.c_int16(x).value
        else:
            if origin_bits == 8:
                real_val = ctypes.c_uint8(x).value
            elif origin_bits == 16:
                real_val = ctypes.c_uint16(x).value

        return ctypes.c_uint32(real_val).value

    @staticmethod
    def _shift_right(x, y, is_arith=False):
        res = x >> y
        if is_arith and (x >> 31) == 1:
            res = res | (((1 << y) - 1) << (32 - y))
        return res

    @staticmethod
    def _multiply(x, y, signed=True):
        neg = False
        if signed and x >> 31 == 1:
            neg = not neg
            x = Instruct._complement(x)
        if signed and y >> 31 == 1:
            neg = not neg
            y = Instruct._complement(y)
        res = x * y
        if neg:
            res = Instruct._complement(res, 64)
        return res



if __name__ == '__main__':
    if len(sys.argv) >= 3:
        max_periods = int(sys.argv[2])
    with open(sys.argv[1], 'r') as fin:
        lines = fin.read().split('\n')
        order = 1
        for line in lines:
            if line == '':
                break
            insts.append(Instruct(line.strip(), order))
            order += 1
        insts.append(Instruct('nop', order))
        insts.append(Instruct('nop', order))

        while pc < len(insts):
            if now_period >= max_periods:
                break
            insts[pc].execute()
