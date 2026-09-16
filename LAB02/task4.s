.text
.globl main

main:
    li x5, 3                # a = 3
    li x6, 4                # b = 4
    li x10, 0x200           # Base address of array D

    li x7, 0                # i = 0

OLoop:
    bge x7, x5, Exit
    li x29, 0               # j = 0

ILoop:
    bge x29, x6, EndI

    # Compute value: x14 = i + j
    add x14, x7, x29        
    slli x15, x29, 4        
    add x15, x10, x15       # x15 = &D[4*j]
    sw x14, 0(x15)          # D[4*j] = i + j

    addi x29, x29, 1        # j++
    beq x0, x0, ILoop

EndI:
    addi x7, x7, 1          # i++
    beq x0, x0, OLoop

Exit:
    beq x0, x0, Exit