# Assembler
x64 Assembler written in Assembly!

Just like `nasm`, this assembly code, inputs a file written in assembly language, and converts it to machine code.

Please note that, it doesn't have all of the operations. Here are operations that it knows what to do. But the general rule for compiling assembly code to machine code is implemented. (Many of the parts of the code doesn't have anything to do with the operation.)

<p float="left">
  <img src="https://user-images.githubusercontent.com/12760574/131022619-1c43c550-ecd9-4f5b-975d-b67727c4354a.png" width="600" />
</p>

The instruction for converting assembly code to machine code is in Intel's manual. I've also uploaded summary and tables for this converting in the files.

## Sample Input/Output:

```
Input:                                    Output:

neg BYTE PTR [esi*8+edx]                  67f61cf2
mov r13d, 0x123                           4189c523010000
and ecx, esi                              21f1
inc rcx                                   48ffc1
dec r14d                                  41ffce
mov QWORD PTR[r11*8+rdx+0x12],	rcx       4a894cda12
adc r11, r12                              4d11e3 
ret 0x123                                 c22301
syscall                                   0f05
shr BYTE PTR [rax+0x123], 0x1234          c0a8230100003412
```

## Compile and Run:
To compile and run this code run the following command:

`nasm -f elf64 ./a.asm && ld -o ./a -e _start ./a.o&& ./a`
