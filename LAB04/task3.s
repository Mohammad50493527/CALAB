.globl main
.data
# test array: 3, 1, 4, 1, 5
# expected descending output: 5, 4, 3, 1, 1
arr: .word 3, 1, 4, 1, 5
len: .word 5

.text
main:
    la   x10, arr           # x10 = base address of array a
    lw   x11, len           # x11 = length of array (len)
    jal  x1, bub         # call bub sort
done:
    addi x0, x0, 0   # nop
    j    done          #ztop execution
bub:
    #check if (a==NULL or len == 0)
    beq  x10, x0, bub_end
    beq  x11, x0, bub_end
    li   t0, 0             
Outer_L:
    bge  t0, x11, bub_end   # if i >= len
    mv   t1, t0             # t1: j = i
Inner_L:
    bge  t1, x11, outer_next    # if j >= len,go to next i
    slli t2, t0, 2       #offset i=i*4
    add  t2, x10, t2        #t2=&a_i
    lw   t3, 0(t2)          #t3 = a_i

    slli t4, t1, 2          # offset j=j * 4
    add  t4, x10, t4        # t4 = &a_j
    lw   t5, 0(t4)          # t5 = a_j
    
    bge  t3, t5, no_swap   # check if(a_i >= a_j) do not swap
    # swap a_i and a_j
    sw   t5, 0(t2)        # a_i = old a_j
    sw   t3, 0(t4)         # a_j = old a_i
no_swap:
    addi t1, t1, 1          # incremtn j++
    j    Inner_L

outer_next:
    addi t0, t0, 1      #increment i++
    j    Outer_L

bub_end:
    jalr x0, 0(x1)      #return to