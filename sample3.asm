.text
main:
        addi $sp, $sp, 100
	addi $sp, $sp, -12     # Reserve space for 3 words
        addi $t0, $zero, 12
        addi $t1, $zero, 5
        addi $t2, $zero, 20
        sw   $t0, 8($sp)       # Store 12 at offset 8
        sw   $t1, 4($sp)       # Store 5 at offset 4
        sw   $t2, 0($sp)       # Store 20 at offset 0
        jal  find_max
        add  $20, $v0, $zero
        j Halt
find_max:
        lw   $a0, 0($sp)
        lw   $a1, 4($sp)
        lw   $a2, 8($sp)
        add  $v0, $a0, $zero
        slt  $t3, $v0, $a1
        bne  $t3, $zero, set_max_a1
        slt  $t3, $v0, $a2
        bne  $t3, $zero, set_max_a2
        jr   $ra
set_max_a1:
        add  $v0, $a1, $zero
        slt  $t3, $v0, $a2
        bne  $t3, $zero, set_max_a2
        jr   $ra
set_max_a2:
        add  $v0, $a2, $zero
        jr   $ra
Halt:

