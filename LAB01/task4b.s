.text
.globl main

main:
    li x20, 0x100       
    li x21, 0x200       
    li x22, 0x300      
    #c[0]= a[0] + b[0]
    lb  x5, 0(x20)      # x5 = a[0]
    lh  x6, 0(x21)      # x6 = b[0]
    add x7, x5, x6      # x7 = a[0] + b[0]
    sw  x7, 0(x22)      # c[0] = x7
    # c[1] = a[1] + b[1]
    lb  x5, 1(x20)      # x5 = a[1]
    lh  x6, 2(x21)      # x6 = b[1]
    add x7, x5, x6      # x7 = a[1] + b[1]
    sw  x7, 4(x22)      # c[1] = x7

    # c[2] = a[2] + b[2]
    lb  x5, 2(x20)      # x5 = a[2]
    lh  x6, 4(x21)      # x6 = b[2]
    add x7, x5, x6      # x7 = a[2] + b[2]
    sw  x7, 8(x22)      # c[2] = x7

    # c[3] = a[3] + b[3]
    lb  x5, 3(x20)      # x5 = a[3]
    lh  x6, 6(x21)      # x6 = b[3]
    add x7, x5, x6      # x7 = a[3] + b[3]
    sw  x7, 12(x22)     # c[3] = x7
end:
    j end