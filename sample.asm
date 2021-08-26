mov rax, QWORD PTR[r11*8+rdx+0x12]
mov QWORD PTR[r11*8+rdx+0x12],	rcx
mov QWORD PTR[r11*1+rdx+0x12],	rcx
adc r11, r12
add WORD PTR [eax], si
sub r11w, r15w


sub r12d, DWORD PTR [r13d]
mov rax, 0x12345
mov r13d, 0x123
and ecx, esi
inc rcx
dec r14d
xor ax, dx
cmp rcx, 0x123
test rsi, rdi
xadd eax, ecx
mov ax, WORD ptr [eax]
xadd ax, bx
xchg al, bl
idiv rcx
imul rcx
bsf eax, DWORD PTR [rsi*4]
bsr r14d, r15d
clc
stc
std
jmp 0x123
jne 0x123
neg DWORD PTR [rcx]
dec r11
idiv QWORD PTR [r11d*1+edx]
imul r11
imul QWORD PTR [r11d*1+r13d]
idiv QWORD PTR [r11d*1+0x123]
neg r13d
neg BYTE PTR [esi*8+edx]
not bh
shl rax
shl DWORD PTR [rax+0x1]
shl WORD PTR [rax+0x1], 0x23
shr rax
shr BYTE PTR [rax+0x1], 0x1234
shr BYTE PTR [rax+0x123], 0x1234
call rax
call QWORD PTR [rcx*8]
pop rax
pop r11w
push rcx
pop rcx
pop rdi
push rsi
ret 0x123
ret
syscall


mov rax, 0x123
inc QWORD PTR [rax*1+r13+0x123]
