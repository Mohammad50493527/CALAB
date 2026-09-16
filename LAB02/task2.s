.text
.globl main

main:
    li x22, 10              # b = 10
    li x23, 4               # c = 4
    li x20, 1               # x = 1 (test case)
    li x5, 1
    beq x20, x5, Case1
    li x5, 2
    beq x20, x5, Case2
    li x5, 3
    beq x20, x5, Case3
    li x5, 4
    beq x20, x5, Case4
    # Default case
    li x21, 0           # a = 0
    beq x0, x0, Exit

Case1:
    add x21, x22, x23   #a=b + c
    beq x0, x0, Exit

Case2:
    sub x21, x22, x23   #a=b - c
    beq x0, x0, Exit

Case3:
    slli x21, x22, 1    #a=b * 2
    beq x0, x0, Exit

Case4:
    srai x21, x22, 1    #a=b / 2

Exit: