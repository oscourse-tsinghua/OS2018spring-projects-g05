.extern main
.global start
start:
  li $sp, 0x80300000
  la $t7, main
  jal $t7
  nop
