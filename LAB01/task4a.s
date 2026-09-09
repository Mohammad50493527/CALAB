.text
.globl main
main:
    li x10, 0x78786464
    li x11, 0xA8A81919

    li x5, 0x100
    sw x10, 0(x5)

    li x6, 0x1F0
    sw x11, 0(x6)

    lhu x12, 0(x5)
    lh  x13, 0(x6)
    lb  x14, 0(x6)

end:
    j end