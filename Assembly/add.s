.data
prompt1:.asciiz "Please enter the first integer"
prompt2:.asciiz "Please enter the second integer"
newline: .asciiz   "\n"
str1: .asciiz "The answer is "
bye: .asciiz "The end\n"
.globl main

.text
main:
	# initialize 
	li	$s0, 10
    li	$s1, 10

	# read in the value
	li	$v0, 5
	syscall
	move 	$s0, $v0

	# read in the value
	li	$v0, 5
	syscall
	move 	$s1, $v0

adding:
    add $s2, $s0, $s1

	li	$v0, 1
	move	$a0, $s2
	syscall

    li	$v0, 4
	la	$a0, newline
	syscall