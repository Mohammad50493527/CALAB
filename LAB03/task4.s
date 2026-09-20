.text
.globl main

main:
    # Set destination buffer address (x)and source string address (y)
    li x10, 0x200           # Base address of destination array x
    li x11, 0x250           # Base address of source array y
    # Initialize a test string in array y: Hi
    li x5, 72               # ASCII 'H'
    sb x5, 0(x11)
    li x5, 105              # ASCII 'i'
    sb x5, 1(x11)
    sb x0, 2(x11)           # Null 
    jal x1, strcpy
    lbu x8, 0(x10)          # x8 will display 72 (H)
    lbu x9, 1(x10)          # x9 will display 105 (i)

Exit:
    beq x0, x0, Exit   # end execution
strcpy:
    addi sp, sp, -4    # Adjust stack pointer for 1 word
    sw   x19, 0(sp)      # Save x19
    li   x19, 0       # i = 0
L1:
    add  x5,x11, x19     # x5 = address of y[i]
    lbu  x6,0(x5)        # x6 = y[i]
    add  x7, x10, x19      # x7 = address of x[i]
    sb   x6,0(x7)         # x[i] = y[i]
    beq  x6,x0, L2       # If y[i] =='\0',exit loop
    addi x19,x19, 1     # i++
    beq  x0, x0, L1      # Repeat loop
L2:
    lw   x19, 0(sp)     # Restore original x19
    addi sp, sp, 4      # Deallocate stack
    jalr x0, 0(x1)        # Return to caller