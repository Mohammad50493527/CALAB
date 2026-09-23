.globl main
.text

main:
    # test with num =5
    addi x10, x0, 5     # put 5 into x10
    jal  x1, ntri    # call ntri(5)
done:
    addi x0, x0, 0          
    j    done      # stop eceuction

ntri:
    addi sp, sp, -8
    sw   x1, 4(sp)          # save return address
    sw   x10, 0(sp)     # save current num
    addi x5, x0, 1          # temp reg x5 = 1
    ble  x10, x5, base_case # jump to base case if num <= 1
    
    # recursive call: ntri(num - 1)
    addi x10, x10, -1       # num = num - 1
    jal  x1, ntri           # call ntri

    addi x6, x10, 0    # copy result of ntriinto x6
    lw   x10, 0(sp)     # restore original num
    lw   x1, 4(sp)   # restore return address
    addi sp, sp, 8   # pop stack
    add  x10, x10, x6   # result = num + ntri(num - 1)
    jalr x0, 0(x1)      # return 

base_case:
    addi x10, x0, 1    # return 1
    addi sp, sp, 8     # pop stack 
    jalr x0, 0(x1)          # return 