%include "in_out.asm"
%include "sys-equal.asm"
%include "file.asm"
%include "table.asm"

section .data
	IFD		dq	0 		;Input File Descriptor
	OFD		dq	0 		;Output File Descriptor

	enterFile	db	"Enter File: ", 0
	enterSave	db	"Enter the name of list file: ", 0
	ERR		db	"Error No. ", 0
	tester	db	"mov QWORD PTR[r11+rdx+0x12],	rcx", 0
	tester1	db	"i.asm", 0
	HEX		db	"0123456789abcdef", 0
	forJcc	db	"0F8", 0
	
	bufferLen	equ	20000		;Maximum size of buffer

	ex1		db	"inc", 0
	ex2		db	"dec", 0
	ex3		db	"cmp", 0
	ex4		db	"xadd", 0
	ex5		db	"xchg", 0
	ex6		db	"idiv", 0
	ex7		db	"imul", 0
	ex8		db	"bsf", 0
	ex9		db	"bsr", 0
	ex10		db	"jmp", 0
	ex11		db	"j", 0
	ex12		db	"neg", 0
	ex13		db	"not", 0
	ex14		db	"shl", 0
	ex15		db	"shr", 0
	ex16		db	"call",0
	ex17		db	"pop",0
	ex18		db	"push",0
	ex19		db	"ret",0

section .bss
	fileName:	resb	20
	fileSave:	resb	20
	buffer:	resb	bufferLen	;Input buffer
	obuffer:	resb	bufferLen	;Output buffer
	dum:		resb	1
	linePointer:resq	1
	obPointer:	resq	1		;Output buffer pointer
	line:		resb	100		;Current Line
	output:	resb	100
	input:	resb	100
	dummy:	resb	100
	backup:	resb	100

	;-----------------------------------|
	Prefix:	resb	5	;Hex		|
	;						|
	REX:		resb	5	;Binary	|
	RexW:		resb	2	;Boolean	|
	RexR:		resb	2	;Boolean	|
	RexX:		resb	2	;Boolean	|
	RexB:		resb	2	;Boolean	|
	;						|
	Opcode:	resb	20	;Binary	|
	codeD:	resb	2	;Boolean	|
	codeW:	resb	2	;Boolean	|
	Mod:		resb	5	;Binary	|
	Reg:		resb	5	;Binary	|
	RM:		resb	5	;Binary	|
	Scale:	resb	5	;Binary	|
	Index:	resb	5	;Binary	|
	Base:		resb	5	;Binary	|	
	Displace:	resb	10	;Hex		|
	Data:		resb	20	;Hex		|
	;-----------------------------------|

	opsize:	resb	1	;Operand size
	dispsize:	resb	1	;Displacement size

	needRex:	resb	1	;Boolean. Does it need Rex
	pre67:	resb	1	;Boolean. Does it need prefix 67
	pre66:	resb	1	;Boolean. Does it need prefix 66

	exep:		resb	1	;Exception?

section .text
	global _start

_start:
	mov	rsi,	obuffer
	mov	[obPointer], rsi

	;Getting the file name
	getInput:
	mov	rsi,	enterFile
	call	printString
	mov	rax,	3
	mov	rbx,	2
	mov	rcx,	fileName
	mov	rdx,	50
	int	80h

	;Replace the 0xA at the end of the name by NULL
	mov	rax,	-1
	nlwhile:
	inc	rax
	mov	bl,	[fileName+rax]
	cmp	bl,	0xA
	jne	nlwhile
	mov	bl,	0
	mov	[fileName+rax],	bl

	openTheFile:
	;Openning File
	mov	rdi,	fileName
	call	openFile
	mov	[IFD],	rax

	cmp	rax,	0
	jl	getInput

	;Reading file to buffer
	mov	rdi,	[IFD]
	mov	rsi,	buffer
	mov	rdx,	10000
	call	readFile
	mov	rsi,	buffer
	mov	[linePointer],	rsi

	LOOP:
	call	ClearAll
	call	getLine
	mov	rsi,	line
	call	printString
	call	newLine
	call	length
	cmp	al,	3
	jl	NLPASS
	call	Assemble
	;call	printAll
	mov	rsi,	output
	call	newLine
	call	printString
	call	newLine

	mov	rdi,	[obPointer]
	call	copy
	mov	[obPointer], rdi

	NLPASS:
	mov	rdi,	[obPointer]
	mov	al,	10
	mov	[rdi], al
	inc	rdi
	mov	[obPointer], rdi
	mov	al,	0
	mov	[rdi], al

	jmp	LOOP


;----------------------------------------------------
Assemble:
;Assembles the operation stored in line memory


;Stage	0	Defaults
;--------------------------------------------
mov	rsi,	RexR
mov	al,	'0'
mov	[rsi], al	;Rex.R=0 Default
mov	rsi,	RexX
mov	al,	'0'
mov	[rsi], al	;Rex.X=0 Default
mov	rsi,	RexB
mov	al,	'0'
mov	[rsi], al	;Rex.B=0 Default

;Resetting prefix and Rex
mov	al,	0
mov	[needRex], 	al
mov	[pre66],	al
mov	[pre67],	al
;--------------------------------------------

;Stage	0.5	Exception Prepair
;--------------------------------------------


Stage1:

;Stage	1	Breaking the line and analyzing
;--------------------------------------------
call	breakInput


;Stage	1.5	Exception aftermath
;--------------------------------------------

mov	rsi,	line		;INC
mov	rdi,	ex1
call	isEqual
cmp	rax,	0
je	noInc
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	incMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
incMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	incNoMod
call	putOne
call	putOne
incNoMod:
mov	rsi,	Reg
call	putZero
call	putZero
call	putZero	;Reg = 000
jmp	noExAfter
noInc:




mov	rsi,	line		;DEC
mov	rdi,	ex2
call	isEqual
cmp	rax,	0
je	noDec
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	decMod

mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
decMod:
mov	rsi,	Mod
mov	al,	[rsi]
cmp	al,	0
jne	decNoMod
call	putOne
call	putOne
decNoMod:
mov	rsi,	Reg
call	putZero
call	putZero
call	putOne	;Reg = 001

jmp	noExAfter
noDec:


mov	rsi,	line		;NEG
mov	rdi,	ex12
call	isEqual
cmp	rax,	0
je	noNeg
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	negMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
negMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	negNoMod
call	putOne
call	putOne
negNoMod:
mov	rsi,	Reg
call	putZero
call	putOne
call	putOne	;Reg = 011
jmp	noExAfter
noNeg:

mov	rsi,	line		;NOT
mov	rdi,	ex13
call	isEqual
cmp	rax,	0
je	noNot
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	notMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
notMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	notNoMod
call	putOne
call	putOne
notNoMod:
mov	rsi,	Reg
call	putZero
call	putOne
call	putZero	;Reg = 010
jmp	noExAfter
noNot:

mov	rsi,	line		;CMP
mov	rdi,	ex3
call	isEqual
cmp	rax,	0
je	noCmp
mov	rsi,	Reg
mov	rdi,	RM
call	copy
mov	rsi,	Reg
call	putOne
call	putOne
call	putOne	;Reg = 111
jmp	noExAfter
noCmp:

mov	rsi,	line		;idiv
mov	rdi,	ex6
call	isEqual
cmp	rax,	0
je	noDiv
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	divMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
divMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	divNoMod
call	putOne
call	putOne
divNoMod:
mov	rsi,	Reg
call	putOne
call	putOne
call	putOne	;Reg = 111
jmp	noExAfter
noDiv:

mov	rsi,	line		;imul
mov	rdi,	ex7
call	isEqual
cmp	rax,	0
je	noMul
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	mulMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
mulMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	mulNoMod
call	putOne
call	putOne
mulNoMod:
mov	rsi,	Reg
call	putOne
call	putZero
call	putOne	;Reg = 101
jmp	noExAfter
noMul:

mov	rsi,	line		;SHL
mov	rdi,	ex14
call	isEqual
cmp	rax,	0
je	noShl
mov	al,	'0'
mov	rsi,	codeD
mov	[rsi], al
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	shlMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
shlMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	shlNoMod
call	putOne
call	putOne
shlNoMod:
mov	rsi,	Reg
call	putOne
call	putZero
call	putZero	;Reg = 100

mov	al,	[Data]
cmp	al,	0
je	noExAfter
mov	rsi,	Opcode
inc	rsi
inc	rsi
inc	rsi
mov	al,	'0'
mov	[rsi],	al
jmp	noExAfter
noShl:



mov	rsi,	line		;SHR
mov	rdi,	ex15
call	isEqual
cmp	rax,	0
je	noShr
mov	al,	'0'
mov	rsi,	codeD
mov	[rsi], al
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	shrMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
shrMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	shrNoMod
call	putOne
call	putOne
shrNoMod:
mov	rsi,	Reg
call	putOne
call	putZero
call	putOne	;Reg = 101

mov	al,	[Data]
cmp	al,	0
je	noExAfter
mov	rsi,	Opcode
inc	rsi
inc	rsi
inc	rsi
mov	al,	'0'
mov	[rsi],	al
jmp	noExAfter
noShr:






noExAfter:


;Stage	2	Handling aftermath
;--------------------------------------------
;If no Base => 32bits displace
;If no base. Base = 101
;------------------------
mov	rsi,	Base
mov	al,	[rsi]
cmp	al,	0
je	ignore32Displace
cmp	al,	'1'
jne	ignore32Displace
inc	rsi
mov	al,	[rsi]
cmp	al,	'0'
jne	ignore32Displace
inc	rsi
mov	al,	[rsi]
cmp	al,	'1'
jne	ignore32Displace
mov	al,	32
mov	[dispsize],	al
ignore32Displace:
;------------------------

;Prefix 66
;------------------------
mov	al,	[opsize]
cmp	al,	16
jne	noNeedPre66
mov	al,	1
mov	[pre66],	al
noNeedPre66:
;------------------------

call	handlePrefix

;Rex 0100
mov	rsi,	REX
call	putZero
call	putOne
call	putZero
call	putZero

;Code.W  &  Rex.W
mov	rsi,	codeW
call	putOne
mov	al,	[opsize]
cmp	al,	8
je	resetCodeW
jmp	checkRexW

resetCodeW:
mov	rsi,	codeW
call	putZero
call	writeNum

checkRexW:
mov	rsi,	RexW
call	putZero
mov	al,	[opsize]
cmp	al,	64
je	resetRexW
jmp	Stage3

resetRexW:
mov	rsi,	RexW
call	putOne


Stage3:
;Stage	3	Displacement & Data & Exceptions

mov	rsi,	line		;XADD
mov	rdi,	ex4
call	isEqual
cmp	rax,	0
je	noXadd
mov	rsi,	Prefix
mov	rdi,	dummy
call	copy
call	putZero
mov	al,	'F'
mov	[rsi], al
inc	rsi
mov	al,	0
mov	[rsi], al
noXadd:

mov	rsi,	line		;XCHG
mov	rdi,	ex5
call	isEqual
cmp	rax,	0
je	noXchg
mov	rsi,	codeD
call	putOne
noXchg:

mov	rsi,	line		;BSF
mov	rdi,	ex8
call	isEqual
cmp	rax,	0
je	noBsf
mov	al,	0
mov	rsi,	codeD
mov	[rsi], al
mov	rsi,	codeW
mov	[rsi], al		;D=W=NULL
mov	rsi,	Reg
mov	rdi,	backup
call	copy
mov	rsi,	RM
mov	rdi,	Reg
call	copy
mov	rsi,	backup
mov	rdi,	RM		;SWAP Reg and RM
call	copy
noBsf:

mov	rsi,	line		;BSR
mov	rdi,	ex9
call	isEqual
cmp	rax,	0
je	noBsr
mov	al,	0
mov	rsi,	codeD
mov	[rsi], al
mov	rsi,	codeW
mov	[rsi], al		;D=W=NULL
mov	rsi,	Reg
mov	rdi,	backup
call	copy
mov	rsi,	RM
mov	rdi,	Reg
call	copy
mov	rsi,	backup
mov	rdi,	RM		;SWAP Reg and RM
call	copy
noBsr:

mov	rsi,	line		;JMP
mov	rdi,	ex10
call	isEqual
cmp	rax,	0
je	noJmp
mov 	al,	32
mov	[opsize], al
mov	rsi,	codeD
mov	al,	0
mov	[rsi], al
mov	rsi,	codeW
mov	[rsi], al
mov	rsi,	Reg
mov	[rsi], al
jmp	handleDispData
noJmp:

mov	rsi,	line		;JCC
mov	rdi,	ex11
call	isEqual
cmp	rax,	0
je	noJcc
mov 	al,	32
mov	[opsize], al
mov	rsi,	codeD
mov	al,	0
mov	[rsi], al
mov	rsi,	codeW
mov	[rsi], al
mov	rsi,	Reg
mov	[rsi], al
mov	rdi,	Prefix
mov	rsi,	forJcc
call	copy
jmp	handleDispData
noJcc:



mov	rsi,	line		;CALL
mov	rdi,	ex16
call	isEqual
cmp	rax,	0
je	noCall
mov	al,	32
mov	[opsize], al
mov	al,	0
mov	[codeD], al
mov	[codeW], al
mov	al,	[Data]
cmp	al,	0
je	callNoData
mov	rsi,	Opcode
call	putOne
call	putOne
call	putOne
call	putZero
call	putOne
call	putZero
call	putZero
call	putZero
mov	rsi,	RM
mov	rax, 	5
call	ClearField
mov	rsi,	Reg
call	ClearField
mov	rsi,	Mod
call	ClearField
jmp	handleDispData
callNoData:
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	callMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
callMod:
mov	rsi,	Mod	;Mod = 11
mov	al,	[rsi]
cmp	al,	0
jne	callNoMod
call	putOne
call	putOne
callNoMod:
jmp	handleDispData
noCall:



mov	rsi,	line		;POP
mov	rdi,	ex17
call	isEqual
cmp	rax,	0
je	noPop
mov	rsi,	Opcode
call	putZero
call	putOne
call	putZero
call	putOne
call	putOne
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	popMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
popMod:
mov	rsi,	Mod	;Mod = NULL
mov	al,	[rsi]
cmp	al,	0
jne	popNoMod
mov	al,	0
mov	[Mod], al
mov	[RM], al	;RM = NULL
mov	[codeD], al
mov	[codeW], al
popNoMod:
mov	al,	'0'
mov	[RexW], al
mov	al, [RexB]
cmp	al,	'1'
je	noPop
mov	al,	0
mov	[needRex], al
noPop:

mov	rsi,	line		;PUSH
mov	rdi,	ex18
call	isEqual
cmp	rax,	0
je	noPush
mov	rsi,	Opcode
call	putZero
call	putOne
call	putZero
call	putOne
call	putZero
mov	rsi,	RM
mov	al,	[rsi]
cmp	al,	0
jne	pushMod
mov	al,	[RexR]	;Swapping Rex.R & Rex.B 
mov	[RexB], al
mov	al,	'0'
mov	[RexR], al
mov	rsi,	Reg
mov	rdi,	RM
call	copy
pushMod:
mov	rsi,	Mod	;Mod = NULL
mov	al,	[rsi]
cmp	al,	0
jne	pushNoMod
mov	al,	0
mov	[Mod], al
mov	[RM], al	;RM = NULL
mov	[codeD], al
mov	[codeW], al
pushNoMod:
mov	rsi,	Reg
call	putOne
call	putOne
call	putZero	;Reg = 110
mov	al,	'0'
mov	[RexW], al
mov	al, [RexB]
cmp	al,	'1'
je	noPush
mov	al,	0
mov	[needRex], al
noPush:

mov	rsi,	line		;RET
mov	rdi,	ex19
call	isEqual
cmp	rax,	0
je	noRet
mov	al,	0
mov	rsi,	codeD
mov	[rsi], al
mov	rsi,	codeW
mov	[rsi], al		;D=W=NULL
mov	al,	16
mov	[opsize], al
mov	rsi,	Reg
mov	al,	0
mov	[rsi], al
mov	rsi,	Mod
mov	[rsi], al
mov	al,	[Data]
cmp	al,	0
je	noRet
mov	rsi,	Opcode
add	rsi,	7
mov	al,	'0'
mov	[rsi], al
noRet:



handleDispData:
call	handleDisp
call	handleData

;Stage	4	Making the output
call	tapeTogether

asRet:
ret
;----------------------------------------------------
breakInput:
;Memory line is the input
;Breaks the input into
;operation	oprand1,	oprand2
;Setting the opcode and inputs the oprands
;into the analyzer
push	rsi

;Operation
mov	rsi,	line
mov	rdi,	input
call	copy

;-----Opcode Calculated-----
call	operCode
push	rsi
mov	rsi,	output
mov	rdi,	Opcode
call	copy
pop	rsi
;---------------------------

mov	al,	[rsi]
cmp	al,	0
je	biRet		;It didn't have any operands

mov	al,	'1'
mov	[codeD], al	;D=1. Default 

inc	rsi	;Ready
push	rsi	;First, the second operand must be processed

mov	rdi,	dummy
call	operandCopy

mov	al,	[rsi]
cmp	al,	0
je	processFirst	;Only had one operand

inc	rsi
;Ignoring tabs and spaces between operands
;-----------------------
findTheStart:
mov	al,	[rsi]
cmp	al,	' '
je	goFurther
cmp	al,	'	'
je	goFurther
jmp	operandStartFound
goFurther:
inc	rsi
jmp	findTheStart
operandStartFound:
;-----------------------

mov	rdi,	input
call	operandCopy
;Process Second operand:
call	processOp


mov	al,	[Reg]
cmp	al,	0
je	processFirst
;The second operand was reg. set D=0
mov	al,	'0'
mov	[codeD], al

processFirst:		;Process the first operand
pop	rsi			;The pointer was pushed
mov	rdi,	input
call	operandCopy
call	processOp

biRet:
pop	rsi
ret

;----------------------------------------------------
processOp:
;Process the operand placed in input
;If it's a memory => MOD R/M, SIB, displacement
;If it's a reg => if Reg is not filled, then Reg
;If the Reg was filled, MOD R/M will be filled
push	rax
push	rsi
push	rdi

call	whiteSpace
call	whiteSpace
mov	rsi,	input
call 	printString
call	newLine

mov	al,	[input]
cmp	al,	'0'
je	poImm

call	regCode
mov	al,	[output]
cmp	al,	'-'
je	poMem

;------Process operand: Register-------
poReg:
mov	al,	[Reg]
cmp	al,	0
jne	poReg2

;-----First Reg-----
poReg1:
call	regCode
mov	rsi,	output
mov	al,	[rsi]
mov	[RexR], al
inc	rsi
mov	rdi,	Reg
call	copy

call	sizeof
mov	[opsize], al

mov	al,	[RexR]
cmp	al,	'1'
je	poFirstRegNeedRex

mov	al,	[opsize]

cmp	al,	64
jne	poRet

poFirstRegNeedRex:
mov	al,	1
mov	[needRex], al

jmp	poRet

;----Second Reg----
poReg2:
call	regCode
mov	rsi,	output
mov	al,	[rsi]
mov	[RexB], al
inc	rsi
mov	rdi,	RM
call	copy

mov	al,	'1'	;Mod=11
mov	rsi,	Mod
mov	[rsi], al
inc	rsi
mov	[rsi], al

call	sizeof
mov	[opsize], al

mov	al,	[RexB]
cmp	al,	'1'
je	poSecRegNeedRex

mov	al,	[opsize]

cmp	al,	64
jne	poRet

poSecRegNeedRex:
mov	al,	1
mov	[needRex], al


jmp	poRet

;------Process operand: Immediate Data-
poImm:
mov	rsi,	input
inc	rsi
inc	rsi
mov	rdi,	Data
call	copy

mov	rsi,	Reg
call	putZero
call	putZero
call	putZero
mov	rsi,	Mod
call	putOne
call	putOne

jmp	poRet

;------Process operand: Memory---------
poMem:

;-----Setting Size-----
mov	rsi,	input
mov	al,	[rsi]
cmp	al,	'B'	;BYTE
je	poSetSize8
cmp	al,	'W'	;WORD
je	poSetSize16
cmp	al,	'D'	;DWORD
je	poSetSize32
cmp	al,	'Q'	;QWORD
je	poSetSize64

poSetSize8:
mov	al,	8
jmp	poSetSize
poSetSize16:
mov	al,	16
jmp	poSetSize
poSetSize32:
mov	al,	32
jmp	poSetSize
poSetSize64:
mov	al,	64
jmp	poSetSize

poSetSize:
mov	[opsize], al

;-----Removing PTR-----
mov	rsi,	input
poWhile1:
	mov	al,	[rsi]
	cmp	al,	'['
	je	poRemovePtr
	cmp	al,	0
	je	poERR		;Didn't find [ for memory!
	inc	rsi
	jmp	poWhile1

poRemovePtr:
mov	rdi,	input
call	copy

mov	rsi,	input
inc	rsi
mov	al,	[rsi]
cmp	al,	'0'	;Direct Addressing
je	poDirect

mov	rdi,	dummy
call	softCopy
mov	al,	[rsi]

cmp	al,	']'
je	poNoSIB
cmp	al,	'*'
je	poSIBwScale
inc	rsi
mov	al,	[rsi]
cmp	al,	'0'
je	poNoSIB
jmp	poSIBNoScale

;------Direct Memory------
poDirect:
mov	rsi,	Mod
call	putZero
call	putZero	;Mod=00
mov	rsi,	RM
call	putOne
call	putZero
call	putZero	;RM=100
mov	rsi,	Scale
call	putZero
call	putZero	;Scale=00
mov	rsi,	Index
call	putOne
call	putZero
call	putZero	;Index=100
mov	rsi,	Base
call	putOne
call	putZero
call	putOne	;Base=101

mov	rsi,	input
inc	rsi
inc	rsi
inc	rsi
mov	rdi,	Displace
call	softCopy
jmp	poRet

;---------No SIB----------
poNoSIB:
;REX.X must be 0
mov	rsi,	RexX
call	putZero

mov	rsi,	input
mov	rdi,	backup
call	copy

mov	rsi,	backup
inc	rsi
mov	rdi,	input
call	softCopy
call	regCode

call	sizeof
cmp	rax,	32
jne	noSIBno67
;Needs prefix 67
mov	al,	1
mov	[pre67],	al


noSIBno67:
mov	al,	[rsi]
cmp	al,	']'
je	noSIBnoDisp
;It has Displacement
inc	rsi
inc	rsi
inc	rsi
mov	rdi,	Displace
call	softCopy

mov	rsi,	Displace
call	length
shl	rax,	2	;Number of bits
cmp	rax,	8
jle	setDispSize8

;Displacement is 32 bit
mov	al,	32
mov	[dispsize],	al
mov	rsi,	Mod
call	putOne
call	putZero
jmp	poNoSIBRM

setDispSize8:
mov	al,	8
mov	[dispsize],	al
mov	rsi,	Mod
call	putZero
call	putOne
jmp	poNoSIBRM

noSIBnoDisp:
mov	rsi,	Mod
call	putZero
call	putZero
jmp	poNoSIBRM

poNoSIBRM:	;Handles RM
mov	rsi,	output	;Reg code
mov	al,	[rsi]
mov	[RexB],	al
inc	rsi

mov	rdi,	RM
call	softCopy

mov	al,	[RexB]
cmp	al,	'0'
je	poRet

;Needs Rex
mov	al,	1
mov	[needRex],	al

jmp	poRet

;------SIB with Scale-----
poSIBwScale:
mov	al,	'0'	;Default
mov	[RexB], al
mov	rsi,	Base
call	putOne	;No Base=101. Default
call	putZero
call	putOne

mov	rsi,	RM
call	putOne
call	putZero
call	putZero	;RM=100

mov	rsi,	input
mov	rdi,	backup
call	copy

mov	rsi,	backup
inc	rsi
mov	rdi,	input
call	softCopy
call	regCode



;---Checking for prefix 67---
call	sizeof
cmp	rax,	32
jne	SIBScaleno67
mov	al,	1
mov	[pre67],	al
SIBScaleno67:
;----------------------------


mov	rsi,	output
mov	al,	[rsi]
mov	[RexX], al
inc	rsi
mov	rdi,	Index
call	copy

;-----Need Rex?-----
mov	al,	[RexX]
cmp	al,	'0'
je	SIBnoRex
mov	al,	1
mov	[needRex],	al
SIBnoRex:
;-------------------

mov	rsi,	backup
inc	rsi
mov	rdi,	dummy
call	softCopy
inc	rsi
mov	al,	[rsi]

mov	rsi,	Scale	;For Setting Scale

cmp	al,	'1'
je	poSetScale1
cmp	al,	'2'
je	poSetScale2
cmp	al,	'4'
je	poSetScale4
cmp	al,	'8'
je	poSetScale8

poSetScale1:	;00
call	putZero
call	putZero
jmp	poSetBase

poSetScale2:	;01
call	putZero
call	putOne
jmp	poSetBase

poSetScale4:	;10
call	putOne
call	putZero
jmp	poSetBase

poSetScale8:	;11
call	putOne
call	putOne
jmp	poSetBase

poSetBase:
;No Base. 32 bit displacement. Default
mov	al,	32
mov	[dispsize], al
mov	rsi,	Displace
call	putZero
call	putZero
call	putZero
call	putZero
call	putZero
call	putZero
call	putZero
call	putZero
mov	rsi,	backup
inc	rsi
mov	rdi,	dummy
call	softCopy
inc	rsi
inc	rsi
mov	al,	[rsi]
cmp	al,	']'
je	setNoDispSIB	;No Base. Set no Disp. Done

inc	rsi
mov	al,	[rsi]
cmp	al,	'0'
je	poSIBDisp

mov	rdi,	input
call	softCopy
push	rsi

;IT has base. undo the 32 bit displace
mov	al,	0
mov	[dispsize], al
mov	rsi,	Displace
mov	rax, 10
call	ClearField
call	regCode
mov	rsi,	output
mov	al,	[rsi]
mov	[RexB], al
inc	rsi
mov	rdi,	Base
call	copy

;------Need Rex?------
mov	al,	[RexB]
cmp	al,	'0'
je	SIBnoRex2
mov	al,	1
mov	[needRex],	al
SIBnoRex2:
;---------------------
pop	rsi
mov	al,	[rsi]
cmp	al,	']'
je	setNoDispSIB	;Set no Disp. Done.
inc	rsi


poSIBDisp:		;Setting Displacement
;RSI must be ready
inc	rsi
inc	rsi
mov	rdi,	Displace
call	softCopy
mov	rsi,	Displace
call	length
shl	rax,	2	;x4. number of bits
cmp	rax,	8
je	set8Disp

mov	al,	32
mov	[dispsize],	al
mov	rsi,	Mod
call	putOne
call	putZero
jmp	poRet

set8Disp:
mov	al,	8
mov	[dispsize], al
mov	rsi,	Mod
call	putZero
call	putOne
jmp	poRet


setNoDispSIB:
mov	rsi,	Mod
call	putZero
call	putZero
jmp	poRet


;----SIB without Scale----
poSIBNoScale:
mov	al,	'0'	;Default
mov	[RexB], al
mov	rsi,	Base
call	putOne	;No Base=101. Default
call	putZero	;Although in this case
call	putOne	;Base MUST exist
mov	rsi,	Scale
call	putZero
call	putZero	;Scale = 00

mov	rsi,	RM
call	putOne
call	putZero
call	putZero	;RM=100

;Inserting *1 after index
;Calling Base with Scale!
mov	rsi,	input
inc	rsi
mov	rdi,	dummy
call	softCopy
push	rsi	;Pointing to +
mov	rdi,	dummy
call	operandCopy
mov	rdi,	rsi	;Pointing to NULL at end
pop	rsi

poShiftWhile:
	mov	al,	[rdi]
	mov	rbx,	rdi
	inc	rbx
	inc	rbx
	mov	[rbx], al
	cmp	rsi,	rdi
	je	insertScale
	dec	rdi
	jmp	poShiftWhile

insertScale:
mov	al,	'*'
mov	[rsi], al
mov	al,	'1'
inc	rsi
mov	[rsi], al
jmp	poSIBwScale



poERR:
mov	rsi,	ERR
call	printString
mov	rax,	4
call	writeNum
jmp	poRet

poRet:
pop	rdi
pop	rsi
pop	rax
ret


;----------------------------------------------------
isEqual:
;is where rsi is pointing equal to edi pointer?
;RAX = 1 is equal. RAX = 0 is not equal
push	rsi
push	rdi
push	rbx

xor	rax,	rax
mov	rbx,	1
	ieWhile:
	mov	al,	[rdi]
	cmp	al,	0
	je	ieRet
	cmp	al,	byte[rsi]
	jne	ieSetDif
	inc	rsi
	inc	rdi
	jmp	ieWhile
	ieSetDif:
	mov	rbx,	0
	inc	rsi
	inc	rdi
	jmp	ieWhile

ieRet:
mov	rax,	rbx
pop	rbx
pop	rdi
pop	rsi
ret
;----------------------------------------------------
handleData:
push	rsi
push	rdi
push	rbx
push	rax

mov	rsi,	Data

mov	al,	[Data]
cmp	al,	0
je	hdRet

;For shl and so, Data may be larger
;than the operation size.
xor	rbx, rbx
xor	rax,	rax
mov	bl,	[opsize]
mov	rsi,	Data
call	length
shl	al,	2
cmp	al,	bl
jle	opsizeLarger
mov	[opsize], al

opsizeLarger:
mov	rsi,	Data
mov	rdi,	backup
call	copy

mov	rsi,	Data
call	length

and	rax,	1
cmp	rax,	1
jne	HDReverse
mov	al,	'0'
mov	rsi,	backup
mov	[rsi], al
inc	rsi
mov	rdi,	rsi
mov	rsi,	Data
call	copy	;Inserted a 0 at beginning Even length

HDReverse:
mov	rsi,	backup
mov	rdi,	dummy
call	copy
mov	rdi,	Data
mov	rbx,	backup
dec	rsi
dec	rsi

HDWhile:
	mov	al,	[rsi]
	mov	[rdi], al
	inc	rdi
	inc	rsi
	mov	al,	[rsi]
	mov	[rdi], al
	inc	rdi
	dec	rsi
	cmp	rsi,	rbx
	je	HDSizePre
	dec	rsi
	dec	rsi
	jmp	HDWhile

;---If possible, Data should be
;Considered 32 bits
HDSizePre:
xor	rax,	rax
mov	al,	[opsize]
push	rax
cmp	al,	64
jne	HDMakeSize

mov	rsi,	Data
call	length
cmp	rax,	8
jg	HDMakeSize
mov	al,	32
mov	[opsize], al

HDMakeSize:		;Insert 0 as needed
push	rdi
xor	rax,	rax
xor	rbx,	rbx
mov	al,	[opsize]
shr	al,	2
mov	bl,	al
mov	rsi,	Data
call	length
sub	rbx,	rax
pop	rdi
mov	rsi,	rdi

HDWhile2:
	cmp	rbx,	0
	je	HDPutNull
	mov	al,	'0'
	mov	[rsi], al
	inc	rsi
	dec	rbx
	jmp	HDWhile2

HDPutNull:
mov	al,	0
mov	[rsi], al
	

HDRet:
pop	rax
mov	[opsize], al
pop	rax
pop	rbx
pop	rdi
pop	rsi
ret

ret
;----------------------------------------------------
handleDisp:
;Reverse two by two and makes up the size
push	rsi
push	rdi
push	rbx
push	rax

mov	al,	[Displace]
cmp	al,	0
je	hdRet

mov	rsi,	Displace
mov	rdi,	backup
call	copy

mov	rsi,	Displace
call	length

and	rax,	1
cmp	rax,	1
jne	hdReverse
mov	al,	'0'
mov	rsi,	backup
mov	[rsi], al
inc	rsi
mov	rdi,	rsi
mov	rsi,	Displace
call	copy	;Inserted a 0 at beginning Even length


hdReverse:
mov	rsi,	backup
mov	rdi,	dummy
call	copy
mov	rdi,	Displace
mov	rbx,	backup
dec	rsi
dec	rsi

hdWhile:
	mov	al,	[rsi]
	mov	[rdi], al
	inc	rdi
	inc	rsi
	mov	al,	[rsi]
	mov	[rdi], al
	inc	rdi
	dec	rsi
	cmp	rsi,	rbx
	je	hdMakeSize
	dec	rsi
	dec	rsi
	jmp	hdWhile

hdMakeSize:		;Insert 0 as needed
mov	al,	0
mov	[rdi], al
push	rdi
xor	rax,	rax
xor	rbx,	rbx
mov	al,	[dispsize]
shr	al,	2
mov	bl,	al
mov	rsi,	Displace
call	length
sub	rbx,	rax
mov	rax,	rbx
pop	rdi
mov	rsi,	rdi

hdWhile2:
	cmp	rbx,	0
	je	hdPutNull
	mov	al,	'0'
	mov	[rsi], al
	inc	rsi
	dec	rbx
	jmp	hdWhile2

hdPutNull:
mov	al,	0
mov	[rsi], al
	

hdRet:
pop	rax
pop	rbx
pop	rdi
pop	rsi
ret
;----------------------------------------------------
tapeTogether:
;Puts every part together. Then create the Hex
push	rsi
push	rax
push	rdi

mov	rdi,	input

mov	al,	[needRex]
cmp	al,	0
je	ttAfterRex

mov	rsi,	REX
call	copy
mov	rsi,	RexW
call	copy
mov	rsi,	RexR
call	copy
mov	rsi,	RexX
call	copy
mov	rsi,	RexB
call	copy

ttAfterRex:
mov	rsi,	Opcode
call	copy
mov	rsi,	codeD
call	copy
mov	rsi,	codeW
call	copy

mov	rsi,	Mod
call	copy
mov	rsi,	Reg
call	copy
mov	rsi,	RM
call	copy

mov	rsi,	Scale
call	copy
mov	rsi,	Index
call	copy
mov	rsi,	Base
call	copy

call	Binary2Hex

mov	rsi,	output
mov	rdi,	backup
call	copy

mov	rsi,	Prefix
mov	rdi,	output
call	copy
mov	rsi,	backup
call	copy

mov	rsi,	Displace
call	copy
mov	rsi,	Data
call	copy


ttRet:
pop	rdi
pop	rax
pop	rsi
ret
;----------------------------------------------------
Binary2Hex:
push	rsi
push	rdi

mov	rbx,	0
xor	rcx,	rcx
mov	rsi,	input
mov	rdi,	output

bhWhile:
	cmp	rbx,	4
	je	bhPutOut
	mov	al,	[rsi]
	cmp	al,	0
	je	bhRet
	shl	rcx,	1
	inc	rbx
	inc	rsi
	cmp	al,	'0'
	je	bhWhile
	inc	rcx
	jmp	bhWhile

	bhPutOut:
	mov	rdx,	HEX
	add	rdx,	rcx
	mov	al,	[rdx]
	mov	[rdi], al
	inc	rdi
	xor	rbx,	rbx
	xor	rcx,	rcx
	jmp	bhWhile

bhRet:
mov	al,	0
mov	[rdi], al
pop	rdi
pop	rsi
ret
;----------------------------------------------------
handlePrefix:
push	rax
push	rsi

mov	rsi,	Prefix
mov	al,	0
mov	[rsi], al

mov	al,	[pre67]
cmp	al,	0
je	after67
mov	al,	'6'
mov	[rsi], al
inc	rsi
mov	al,	'7'
mov	[rsi], al
inc	rsi
mov	al,	0
mov	[rsi], al

after67:
mov	al,	[pre66]
cmp	al,	0
je	hpRet
mov	al,	'6'
mov	[rsi], al
inc	rsi
mov	[rsi], al
inc	rsi
mov	al,	0
mov	[rsi], al


hpRet:
pop	rsi
pop	rax
ret
;----------------------------------------------------
putZero:
;Puts one '0' to where rsi is pointing. rsi++
push	rax
mov	al,	'0'
mov	[rsi], al
inc	rsi
mov	al,	0
mov	[rsi], al 	;Null at end
pop	rax
ret

putOne:
;Puts one '1' to where rsi is pointing. rsi++
push	rax
mov	al,	'1'
mov	[rsi], al
inc	rsi
mov	al,	0
mov	[rsi], al	;Null at end
pop	rax
ret
;----------------------------------------------------
copy:
;Copies the content of the memory which rsi is
;pointing, to the memory pointed by rdi.
;Copies till reached Null or ',' or ' ' or tab
;Changes RSI, RDI
;Puts NULL at the end of the rdi
push	rax

xor	rax,	rax
copyWhile:
	mov	al,	[rsi]
	cmp	al,	0
	je	copyRet
	cmp	al,	' '
	je	copyRet
	cmp	al,	','
	je	copyRet
	cmp	al,	9	;Tab
	je	copyRet
	cmp	al,	10	;NL
	je	copyRet
	mov	[rdi], al
	inc	rsi
	inc	rdi
	jmp	copyWhile

copyRet:
mov	al,	0	;Put NULL at the end
mov	[rdi], al

pop	rax
ret
;----------------------------------------------------
softCopy:
;Same as copy. More delimiter are defined.
;Delimiters: 'NULL tab,[]+*'
;Changes RSI and RDI
;Puts NULL at the end of the rdi
push	rax

xor	rax,	rax
scopyWhile:
	mov	al,	[rsi]
	cmp	al,	0
	je	scopyRet
	cmp	al,	' '
	je	scopyRet
	cmp	al,	','
	je	scopyRet
	cmp	al,	9	;Tab
	je	scopyRet
	cmp	al,	'*'
	je	scopyRet
	cmp	al,	'['
	je	scopyRet
	cmp	al,	']'
	je	scopyRet
	cmp	al,	'+'
	je	scopyRet
	cmp	al,	10	;NL
	je	scopyRet
	mov	[rdi], al
	inc	rsi
	inc	rdi
	jmp	scopyWhile

scopyRet:
mov	al,	0	;Put NULL at the end
mov	[rdi], al

pop	rax
ret
;----------------------------------------------------
hardCopy:
;Copies the content of the memory which rsi is
;pointing, to the memory pointed by rdi.
;Copies till reached Null
;Changes RSI, RDI
;Puts NULL at the end of the rdi
push	rax

xor	rax,	rax
hcopyWhile:
	mov	al,	[rsi]
	cmp	al,	0
	je	hcopyRet
	cmp	al,	10	;NL
	je	hcopyRet
	mov	[rdi], al
	inc	rsi
	inc	rdi
	jmp	hcopyWhile

hcopyRet:
mov	al,	0	;Put NULL at the end
mov	[rdi], al
pop	rax
ret
;----------------------------------------------------
operandCopy:
;Copies the content of the memory which rsi is
;pointing, to the memory pointed by rdi.
;Copies till reached Null and ','
;Changes RSI, RDI
;Puts NULL at the end of the rdi
push	rax

xor	rax,	rax
opcopyWhile:
	mov	al,	[rsi]
	cmp	al,	0
	je	opcopyRet
	cmp	al,	','
	je	opcopyRet
	mov	[rdi], al
	inc	rsi
	inc	rdi
	jmp	opcopyWhile

opcopyRet:
mov	al,	0	;Put NULL at the end
mov	[rdi], al
pop	rax
ret

;----------------------------------------------------
ClearField:
;Clears the field pointed by rsi
;Size in RAX
push	rsi
push	rax
push	rbx

mov	bl,	0
cfWhile:
	cmp	rax,	0
	je	cfRet
	mov	[rsi], bl
	inc	rsi
	dec	rax
	jmp	cfWhile

cfRet:
pop	rbx
pop	rax
pop	rsi
ret
;----------------------------------------------------
ClearAll:
;Clears all field.
push	rax

mov	rsi,	Prefix
mov	rax,	5
call	ClearField
mov	rsi,	REX
call	ClearField
mov	rsi,	Mod
call	ClearField
mov	rsi,	Reg
call	ClearField
mov	rsi,	RM
call	ClearField
mov	rsi,	Scale
call	ClearField
mov	rsi,	Index
call	ClearField
mov	rsi,	Base
call	ClearField
mov	rax,	2
mov	rsi,	RexW
call	ClearField
mov	rsi,	RexR
call	ClearField
mov	rsi,	RexX
call	ClearField
mov	rsi,	RexB
call	ClearField
mov	rsi,	codeD
call	ClearField
mov	rsi,	codeW
call	ClearField
mov	rax,	10
mov	rsi,	Opcode
call	ClearField
mov	rsi,	Displace
call	ClearField
mov	rax,	20
mov	rsi,	Data
call	ClearField
mov	rsi,	line
mov	rax,	100
call	ClearField

mov	al,	0
mov	[opsize], al
mov	[dispsize], al
mov	[needRex], al
mov	[pre67], al
mov	[pre66], al

pop	rax
ret
;----------------------------------------------------
sizeof:
;Calculates the size of the register stored in input
;Returns the answer in rax: Number of bits.
push	rsi
push	rbx
push	rcx

mov	rsi,	input
xor	rax,	rax
xor	rbx,	rbx
xor	rcx,	rcx

call	lastChar
mov	bl,	al	;Right most char
mov	al,	[rsi]	;Left most char

cmp	bl,	'b'	;r8b, r9b, ...
je	soRet8
cmp	bl,	'w'	;r8w,	r9w, ...
je	soRet16
cmp	bl,	'd'	;r8d,	r9d, ...
je	soRet32
cmp	bl,	'h'	;ah, bh, ...
je	soRet8
cmp	bl,	'l'	;al, bl, ...
je	soRet8
cmp	al,	'e'	;eax, ebx, ...
je	soRet32
cmp	al,	'r'	;r8, rax, ....
je	soRet64
jmp	soRet16	;ax, cx, si, bp, ...

soRet64:
mov	rax,	64
jmp	soRet

soRet32:
mov	rax,	32
jmp	soRet

soRet16:
mov	rax,	16
jmp	soRet

soRet8:
mov	rax,	8
jmp	soRet

soRet:
pop	rcx
pop	rbx
pop	rsi
ret
;----------------------------------------------------
lastChar:
;Returns the last char of the string where rsi
;is pointing to in al: ASCII code.
push	rsi
lcWhile:
	mov	al,	[rsi]
	cmp	al,	0
	je	lcFound
	inc	rsi
	jmp	lcWhile

	lcFound:
	dec	rsi
	xor	rax,	rax
	mov	al,	[rsi]
	jmp	lcRet

lcRet:
pop	rsi
ret
;----------------------------------------------------
length:
;Calculates the length of the string which rsi is
;pointing to and returns the answer in rax.
push	rbx
push	rsi

xor	rax,	rax
lenWhile:
	cmp	byte[rsi], 0
	je	lenRet
	inc	rax
	inc	rsi
	jmp	lenWhile

lenRet:
pop	rsi
pop	rbx
ret
;----------------------------------------------------
getLine:
;Get one line from the Input file and puts it
;in the 'line' memory

push	rsi
push	rdi
push	rax

mov	rsi,	[linePointer]
mov	rdi,	line

cmp	byte[rsi], 0 ;EOF
jne	glWhile

;EOF
pop	rax
pop	rdi
pop	rsi
jmp	writeInFile

glWhile:
	xor	rax,	rax
	mov	al,	[rsi]
	cmp	al,	0xA
	je	glPutNull
	cmp	al,	0
	je	glPutNull2
	mov	[rdi], al
	inc	rsi
	inc	rdi

	jmp	glWhile

glPutNull:
	inc	rsi
	mov	[linePointer], rsi
	mov	byte[rdi],	0
	jmp	glRet

glPutNull2:	;The next time getLine is called,
    		;the program will terminate
	mov	[linePointer],	rsi
	mov	byte[rdi],	0
	jmp	glRet

glRet:
pop	rax
pop	rdi
pop	rsi
ret
;----------------------------------------------------
writeInFile:

	mov	rsi,	enterSave
	call	printString
	mov	rax,	3
	mov	rbx,	2
	mov	rcx,	fileSave
	mov	rdx,	50
	int	80h

	;Replace the 0xA at the end of the name by NULL
	mov	rax,	-1
	wiwhile:
	inc	rax
	mov	bl,	[fileSave+rax]
	cmp	bl,	0xA
	jne	wiwhile
	mov	bl,	0
	mov	[fileSave+rax],	bl


mov	rdi,	fileSave
call	createFile

mov	[OFD], rax
mov	rdi,	[OFD]
mov	rsi,	obuffer
call	length
mov	rdx,	rax
call	writeFile

mov	rdi,	[OFD]
call	closeFile


;call	newLine
;mov	rsi,	obuffer
;call	printString
;call	newLine


jmp	Exit

;----------------------------------------------------

Exit:
	mov	rax,	1
	mov	rbx,	0
	int	0x80
