.globl main
.text
# This programee return te maximum of the number you give as input for in this particular case we are
# doing this with three values.
# for exapmple in 14,42 and 27 it will retun 42
main:
    addi x10, x0, 14    # a = 14
    addi x11, x0, 42  # b = 42
    addi x12, x0, 27   # c = 27
    jal  x1, max3        # call max3
done:
    addi x0, x0, 0      
    j    done           #stop execution

max3:
    addi sp, sp, -8
    sw   x1,  4(sp)         # save ra 
    sw   x12, 0(sp)         # save c on stack

    # first call: max2(a, b)
    # x10 and x11 are already holding a and b
    jal  x1, max2      #returns larger of a and b in x10

    # second call
    lw   x11, 0(sp)         # load c from stack into second arg register x11
    jal  x1, max2      # max2(max(a, b), c) final max in x10\

    lw   x1, 4(sp)          # restore ra
    addi sp, sp, 8          #pop stack frame
    jalr x0, 0(x1)          # return

max2:
    bge  x10, x11, max2_done # if num1 >= num2, x10 is already the max
    addi x10, x11, 0     # else,put num2 into x10

max2_done:
    jalr x0, 0(x1)  # return 