.globl main
.text

main:
#test val 4
    addi x10, x0, 4         # x10 = 4 (argument n)
    jal  x1, fact_iter      # call iterative factorial

done:
    addi x0, x0, 0          # NOP
    j    done        # end executoin

fact_iter:
    addi x5, x0, 1          # long acc = 1;

while_loop:
    ble  x10, x0, loop_end  # if n <= 0, break loop
    mul  x5, x5, x10      # acc = acc * n;
    addi x10, x10, -1     # n = n - 1;
    jal  x0, while_loop     #  jump back to loop

loop_end:
    addi x10, x5, 0         # move acc into return register x10
    jalr x0, 0(x1)     # return call