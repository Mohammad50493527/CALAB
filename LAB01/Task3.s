.text
.globl main

main:
    li x20, 5          
    li x21, 0          

    addi x20, x21, 32  # a = b + 32
    add x5, x20, x21   # x5 =a + b
    addi x22, x5, -5   # d= (a +b) - 5
    sub x5, x20, x22   # x5 = a - d
    sub x6, x21, x20   # x6 = b - a
    add x5, x5, x6     # x5 = (a - d) + (b - a)
    add x23, x5, x22   # e = ((a - d) + (b - a)) + d
    add x5, x20, x21   # x5 = a + b
    add x5, x5, x22    # x5 = a + b + d
    add x5, x5, x23    # x5 = a + b + d + e
    add x23, x5, x0    # e = a + b + d + e
end:
    j end              