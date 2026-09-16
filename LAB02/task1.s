.text
.globl main

#listing 3
main:
    li x22, 8 #loadimmediate
    li x23, 8
    li x20, 3
    li x21, 1

    bne x22, x23, Else
    add x19, x20, x21
    beq x0, x0, Exit
    Else: sub x19, x20, x21
    Exit:

#listing 4
main:
    li x22, 0
    li x24, 11
    li x25, 0x100

    Loop: 
    slli x10, x22, 2 #Shift left logical immediate
    add x10, x10, x25 
    ld x9, 0(x10)
    bne x9, x24, Exit 
    addi x22, x22, 1
    beq x0, x0, Loop
    Exit:   
    