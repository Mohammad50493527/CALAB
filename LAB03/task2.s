.text
.globl main

main:
    #test values
    li x10, 10           # g = 10
    li x11, 20           # h = 20
    li x12, 5              #i = 5
    li x13, 2               #j = 2

    
    addi x9, x10, 0 #save x10 so it is not lost
    jal x1, leaf_example
Exit:
    beq x0, x0, Exit        # exit loop
leaf_example:
   #making space in stack
    addi sp, sp, -12
    sw   x18, 8(sp)       # Save x18
    sw   x19, 4(sp)       #Save x19
    sw   x20, 0(sp)        #Save x20
    # Compute:f=(g +h)-(i + j)
    add  x18, x10, x11      # x18 = g+h
    add  x19, x12, x13      # x19 =i+ j
    sub  x20, x18, x19      # x20 =(g + h)-(i+ j)
    # Return value placed in x10
    addi x10, x20, 0        # x10=f

    lw   x20, 0(sp)         #Restore x20
    lw   x19, 4(sp)         #Restore x19
    lw   x18, 8(sp)         #Restore x18
    addi sp, sp, 12        #Deallocate stack
    jalr x0, 0(x1)          #Return