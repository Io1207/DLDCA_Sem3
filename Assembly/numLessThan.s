	.data
prompt1:	.asciiz "Enter the Re  "
prompt2:	.asciiz "Enter the Im  "
str1:	.asciiz "the result is: "
newline: .asciiz	"\n"
bye:	.asciiz	"Goodbye!\n"

.align 4
A:  .word 0 0
    .word -1 2
    .word 0 2
    .word -1 -1

.align 4
len: .word 4
	.globl	main

.text


numLessThan:
    #ptr to array in stack ptr, rest are directly passed
    #a1 is the real part a2 is the imaginary part
    #len is in a3 start is 0 is in a0
    #put result in $s6
    lw $t0, 0($a0) #like i for loop
    slt $t7,$t0,$a3 #loop condition
    beq $t7,1,isLessThan
    jr $ra

isLessThan:
    sll $t2, $t0, 2
    add $t3,$t2,$sp
    slt $t1,$a1,$t3 #is elmt.re less a[i].re
    beq $t1,1,makeChangeYes
    beq $a1,$t3,CheckOther

CheckOther:
    addi $t3,$t2,4
    add $t3, $t3, $sp
    slt $t1,$a2, $t3
    beq $t1,1,makeChangeYes
    bne $t1,1,makeChangeNo

makeChangeYes:
    addi $t0,$t0,1
    addi $s6,$s6,1
    j numLessThan

makeChangeNo:
    addi $t0,$t0,1
    j numLessThan

main:
    # initialize 
	li	$s0, 10
    li	$s1, 10

    #prompt,in,read
    li	$v0, 4
	la	$a0, prompt1
	syscall
    li	$v0, 5
	syscall
	move 	$s0, $v0

    li	$v0, 4
	la	$a0, prompt2
	syscall
    li	$v0, 5
	syscall
	move 	$s1, $v0

    la $s4,A
    la $t1, len
    lw $s5,0($t1)

    addi $sp, $sp,-4
    move $sp, $s4
    move $a1, $s0
    move $a2, $s1
    move $a0, $0
    move $a3, $s5
    li $s6,0

    jal numLessThan
