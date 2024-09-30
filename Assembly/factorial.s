# int factorial(int n)
#{
#   if (n==0) return 1;
#   else return n*factorial(n-1)
#}
#
#int main()
#{
#   int n=7;
#   return factorial(n)
#}
.text

Factorial:
    addi $sp,$sp,-8
    sw $ra,4($sp)
    sw $a0,0($sp)
    bne $a0,$zero,Else
    addi $v1,$zero,1
    j exit

Else: #when n not zero
    addi $a0,$a0,-1
    jal Factorial
    lw $a0,0($sp)
    mul $v1,$v1,$a0 #n*(n-1)!

exit:
    lw $ra,4($sp)
    addi $sp,$sp,8 #reverting stack back to original state
    jr $ra

main:
    li $v1,1
    li $a0,5
    j Factorial