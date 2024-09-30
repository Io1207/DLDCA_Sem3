.data

.align 4
A:  .word 0 0 5
    .word -1 2
    .word 0 2
    .word -1 -1

.align 4
len: .word 4
.globl main

.text
main:
    la $t0,A
    la $t1,16($t0)
    lw $t2,0($t1)
    lw $t3,4($t1)
    la $t5,len
    lw $s1,0($t5)
    add $s0,$t2,$t3
    jr $ra