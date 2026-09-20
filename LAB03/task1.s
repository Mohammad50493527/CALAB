.text
.globl main

main:
    addi x10, x0, 12        # a = 12
    addi x11, x0, 12        # b = 12
    jal x1, sum             

Exit:
    beq x0, x0, Exit        #stop execution (result remains in x10)

sum:
    add x10, x11, x10       #x10 =a + b
    jalr x0, 0(x1)          #Return to caller