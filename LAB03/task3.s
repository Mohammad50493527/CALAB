.text
.globl main

main:
    li x10, 0x200           # Setup array
    li x5, 45    #v[0] = 45           
    li x6, 99   # v[1] = 99            
    sw x5, 0(x10)   # Memory at 0x200 = 45
    sw x6, 4(x10)   # Memory at 0x204 = 99
    li x11, 0               # k in x11
    jal x1, swap #cal function
    
    lw x5, 0(x10)           # x5 now contains 99
    lw x6, 4(x10)           # x6 now contains 45
    

Exit:
    beq x0, x0, Exit        # stoploop
swap:
    slli x12, x11, 2        # x12 = k * 4 ofset
    add  x12, x10, x12      # x12 = address of v[k]
    # Load v[k] and v[k+1]
    lw   x13, 0(x12)        # temp = v[k]
    lw   x14, 4(x12)        # x14 = v[k+1]
    # Store swapped values back into memory
    sw   x14, 0(x12)        # v[k] = v[k+1]
    sw   x13, 4(x12)        # v[k+1] = temp
    jalr x0, 0(x1)          # Return 