%include "sys-equal.asm"

;Register Table
regTable	db	"rax", 10, "eax", 10, "ax", 10, "al", 10, "rcx", 10, "ecx", 10, "cx", 10, "cl", 10, "rdx", 10, "edx", 10, "dx", 10, "dl", 10, "rbx", 10, "ebx", 10, "bx", 10, "bl", 10, "rsp", 10, "esp", 10, "sp", 10, "ah", 10, "rbp", 10, "ebp", 10, "bp", 10, "ch", 10, "rsi", 10, "esi", 10, "si", 10, "dh", 10, "rdi", 10, "edi", 10, "di", 10, "bh", 10, "r8", 10, "r8d", 10, "r8w", 10, "r8b", 10, "r9", 10, "r9d", 10, "r9w", 10, "r9b", 10, "r10", 10, "r10d", 10, "r10w", 10, "r10b", 10, "r11", 10, "r11d", 10, "r11w", 10, "r11b", 10, "r12", 10, "r12d", 10, "r12w", 10, "r12b", 10, "r13", 10, "r13d", 10, "r13w", 10, "r13b", 10, "r14", 10, "r14d", 10, "r14w", 10, "r14b", 10, "r15", 10, "r15d", 10, "r15w", 10, "r15b", 10, 0

;Operation Table
operTable	db	"adc 000100", 10, "add 000000", 10, "mov 100010", 10, "sbb 000110", 10, "sub 001010", 10, "and 001000", 10, "dec 111111", 10, "inc 111111", 10, "or 000010", 10, "xor 001100", 10, "and 001000", 10, "cmp 001110", 10, "test 100001", 10, "xadd 110000", 10, "xchg 100001", 10, "cmp 001110", 10, "idiv 111101", 10, "imul 111101", 10, "bsf 0000111110111100", 10, "bsr 0000111110111101", 10, "clc 11111000", 10, "cld 11111100", 10, "stc 11111001", 10, "std 11111101", 10, "jmp 11101001", 10, "jo 0000", 10,"jno 0001", 10,"jnae 0010", 10,"jb 0010", 10,"jnb 0011", 10,"jae 0011", 10,"je 0100", 10,"jz 0100", 10,"jne 0101", 10,"jnz 0101", 10,"jbe 0110", 10,"jna 0110", 10,"jnbe 0111", 10,"ja 0111", 10,"js 1000", 10,"jns 1001", 10,"jp 1010", 10,"jpe 1010", 10,"jnp 1011", 10,"jpo 1011", 10,"jl 1100", 10,"jnge 1100", 10,"jnl 1101", 10,"jge 1101", 10,"jle 1110", 10,"jng 1110", 10,"jnle 1111", 10,"jg 1111", 10, "neg 111101", 10, "not 111101", 10, "shl 110100", 10, "shr 110100", 10, "call 11111111", 10, "pop 10001111", 10, "push 11111111", 10, "ret 11000011", 10, "syscall 0000111100000101", 10, 0


;----------------------------------------------------
regCode:
;Returns the reg code of the register in input
;to output, using the regTable.

push	rsi	;To table
push	r9	;Counter
push	rdi	;To input
push	rax	;tmp1
push	rbx	;flag

xor	r9,	r9
xor	rbx,	rbx
mov	rsi,	regTable
mov	rdi,	input
rcWhile:
	xor	rax,	rax
	mov	al,	[rsi]
	cmp	al,	10	;End of the string
	je	rcCheck
	cmp	al,	0
	je	rcError	;End of the table

	cmp	al, byte[rdi]
	je	rcContinue
	
	mov	rbx,	1	;Set flag to 1. Mismatch
	
	rcContinue:
	inc	rsi
	inc	rdi
	jmp	rcWhile
	
	rcCheck:
	cmp	rbx,	0
	je	rcFound
	inc	r9		;Inc counter
	inc	rsi
	mov	rdi,	input
	mov	rbx,	0	;Reset flag
	jmp	rcWhile

	rcFound:
	shr	r9,	2	;Divided by 4
	mov	rsi,	output ;To write Output
	mov	rax,	8
	and	rax,	r9
	cmp	rax,	0
	je	tputZero1
	call	tputOne
	jmp	rc4

	tputZero1:
	call	tputZero
	
	rc4:
	mov	rax,	4
	and	rax,	r9
	cmp	rax,	0
	je	tputZero2
	call	tputOne
	jmp	rc2
		
	tputZero2:
	call	tputZero

	rc2:
	mov	rax,	2
	and	rax,	r9
	cmp	rax,	0
	je	tputZero3
	call	tputOne
	jmp	rc1

	tputZero3:
	call	tputZero

	rc1:
	mov	rax,	1
	and	rax,	r9
	cmp	rax,	0
	je	tputZero4
	call	tputOne
	jmp	rc0

	tputZero4:
	call	tputZero

	rc0:
	mov	al,	0
	mov	[rsi], al	;Put Null at the end
	jmp	rcRet

	rcError:
	;Not Found: Not a register
	mov	al,	"-"
	mov	rsi,	output
	mov	[rsi],	al
	mov	al,	0
	inc	rsi
	mov	[rsi],	al
	
rcRet:
pop	rbx
pop	rax
pop	rdi
pop	r9
pop	rsi
ret

tputOne:
;Puts '1' to where rsi is pointing and increases rsi
mov	al,	"1"
mov	[rsi], al
inc	rsi
ret

tputZero:
;Puts '0' to where rsi is pointing and increases rsi
mov	al,	"0"
mov	byte[rsi], al
inc	rsi
ret
;----------------------------------------------------

operCode:
;Operation code. Returns the opcode of the operation
;stored in input, to output. Uses operTable.
push	rsi	;To table
push	rdi	;To input
push	rax	;tmp1
push	rbx	;flag

xor	rbx,	rbx
mov	rsi,	operTable
mov	rdi,	input
ocWhile:
	xor	rax,	rax
	mov	al,	[rsi]
	cmp	al,	' ' 	;End of string
	je	ocCheck	;Check for mismatches

	cmp	al,	0
	je	ocErr		;End of the table

	cmp	al,	byte[rdi]
	je	ocContinue

	mov	rbx,	1	;Set flag to 1. Mismatch occured

	ocContinue:		;Continue
	inc	rsi
	inc	rdi
	jmp	ocWhile

	ocCheck:
	cmp	rbx,	0
	je	ocFound
	;----------------------
	ocWhile2:		;While starting the next word
	mov	al,	[rsi]
	cmp	al,	10
	je	ocReady2Continue
	inc	rsi
	jmp	ocWhile2

	ocReady2Continue:
	inc	rsi
	xor	rbx,	rbx	;Resetting flag
	mov	rdi,	input
	jmp	ocWhile
	;----------------------
	
	ocFound:
	mov	rdi,	output
	inc	rsi		;Starting of the oper code
	ocWhile3:		;Copying the code to output
		mov	al,	[rsi]
		cmp	al,	10
		je	ocPutNull
		mov	[rdi], al
		inc	rdi
		inc	rsi
		jmp	ocWhile3
	ocPutNull:		;Put null at the end of output
		mov	al,	0
		mov	[rdi], al
		jmp	ocRet
	
	ocErr:
	mov	rsi,	ERR
	call	printString
	mov	rax,	2	;ERR No. 2: Operation not found.
	call	writeNum
	call	whiteSpace
	mov	rsi,	input
	call	printString
	call	newLine
	jmp	ocRet

ocRet:
pop	rbx
pop	rax
pop	rdi
pop	rsi
ret

;----------------------------------------------------


