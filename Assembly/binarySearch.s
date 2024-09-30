#int binarySearch(int *A, int len, int start, int end, int val)
#{
    #int middle=(start+end)/2;
    #if (start<end)
    #{
        #if (A[middle]==val)
        #{
            #return middle;
        #}
        #else if (A[middle]<val) start=middle;
        #else end=middle;
        #return binarySearch(A,len,start,end,val);
    #}
    #else if (start==val) return start; #start=end=val start(=val)>end not possible, that would have been caught in the firsat case
    #else return -1;
# }
.data

newline: .asciiz   "\n"
prompt1:.asciiz "Please enter the value you are searching for"
str1: .asciiz "The index at which val exists "

.align 4
A:  .word 5 9 10 15 18 23 24 76 100
# val: .word 11

.globl main
.text

MidLess:
    addi $a1,$t0,1
    # lw $ra,20($sp)
    jal BinarySearch
    lw $ra,20($sp)
    lw $a1,8($sp)
    addi $sp,$sp,24
    jr $ra

MidGreat:
    addi $a3,$t0,-1
    # lw $ra,20($sp)
    jal BinarySearch
    lw $ra,20($sp)
    lw $a3,16($sp)
    addi $sp,$sp,24
    jr $ra

returnMid:
    add $v1,$t0,$0
    lw $ra,20($sp)
    addi $sp,$sp,24
    jr $ra

returnSaved:
    add $v1,$a1,$0
    lw $ra,20($sp)
    addi $sp,$sp,24
    jr $ra

returnFail:
    li $v1,-1
    lw $ra,20($sp)
    addi $sp,$sp,24
    jr $ra

exit1:
    sll $t6,$a1,2
    add $t7,$a0,$t6 #accessing A[start]
    beq $t7,$a2,returnSaved
    bne $t7,$a2,returnFail

BinarySearch:
    addi $sp,$sp,-24
    sw $s0,0($sp)
    sw $a0,4($sp)
    sw $a1,8($sp)
    sw $a2,12($sp)
    sw $a3,16($sp)
    sw $ra,20($sp)

    add $t1,$a1,$a3
    srl $t0,$t1,1 #middle
    slt $t2,$a1,$a3
    beq $t2,$0,exit1 #if start>=end
    sll $t3,$t0,2 #4*middle
    add $t4,$a0,$t3 #accessing mid of A
    lw $t4,0($t4)
    lw $s1,0($a2)
    beq $t4,$s1,returnMid
    slt $t5,$t4,$s1
    bne $t5,$0,MidLess
    beq $t5,$0,MidGreat

    
main:
    li $s0, 10
    # prompt for input
	li	$v0, 4
	la	$a0, prompt1
	syscall

	# read in the value
	li	$v0, 5
	syscall
	move 	$s0, $v0

    addi $sp, $sp, -4
    sw $s0, 0($sp)

    la $a0,A #array
    li $a1,0 #start
    move $a2,$sp #val
    li $a3,8 #end

    addi $sp, $sp, -4
    sw $s0, 0($sp)

    # li $s,9 #length passed thru stack
    jal BinarySearch

    li	$v0, 4
	la	$a0, str1
	syscall

    li	$v0, 1
	move	$a0, $v1
	syscall

    li	$v0, 4
	la	$a0, newline
	syscall