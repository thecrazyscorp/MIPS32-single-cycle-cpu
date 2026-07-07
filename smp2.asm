.text
main:
addi $a0,$0,10
addi $a1,$0,20
jal add_two
add $s0, $0, $v0
addi $v0, $0, 10
syscall

add_two:
add $v0, $a0, $a1
jr $ra