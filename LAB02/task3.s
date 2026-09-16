.text
.globl main

main:
    li x24, 0x200           
    li x25, 10              
    li x22, 0               # i = 0
Loop1:
    bge x22, x25, End1
    slli x5, x22, 2        #Offset = i * 4
    add x6, x24, x5        #Address of a[i]
    sw x22, 0(x6)          #a[i] = i
    addi x22, x22, 1       #i++
    beq x0, x0, Loop1
End1:
    li x23, 0              
    li x22, 0               
Loop2:
    bge x22, x25, End2
    slli x5, x22, 2         #Offset = i * 4
    add x6, x24, x5         #Address of a[i]
    lw x7, 0(x6)            #Load a[i]
    add x23, x23, x7        #sum = sum + a[i]
    addi x22, x22, 1        #i++
    beq x0, x0, Loop2
End2: