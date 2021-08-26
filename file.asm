%include "sys-equal.asm"

errCreate	db	"Error creating file ",	NL,	0
errClose	db	"Error closing file ",	NL,	0
errWrite	db	"Error writing file ",	NL,	0
errOpen	db	"Error openning file ",	NL,	0
errRead	db	"Error reading file ",	NL,	0
sucCreate	db	"File created ",		NL,	0
sucClose	db	"File closed ",		NL,	0
sucWrite	db	"File is written ",	NL,	0
sucOpen	db	"File opened ",		NL,	0
sucRead	db	"File read ",		NL,	0

createFile:
;rdi: file 	name
;rsi:	file	permission
	mov	rax,	sys_create
	mov	rsi,	sys_IRUSR | sys_IWUSR
	syscall
	cmp	rax,	-1 	;File descriptor
	jle	createErr
	push	rsi
	mov	rsi,	sucCreate
	call	printString
	pop	rsi
	ret
	createErr:
	mov	rsi,	errCreate
	call	printString
	ret

openFile:
;rdi:	file	name
;rsi:	file	access
	mov	rax,	sys_open
	mov	rsi,	O_RDWR
	syscall
	cmp	rax,	-1	;File descriptor
	jle	openErr
	push	rsi
	mov	rsi,	sucOpen
	call	printString
	pop	rsi
	ret
	openErr:
	mov	rsi,	errOpen
	call	printString
	ret

writeFile:
;rdi:	file	descriptor
;rsi:	buffer
;rdx:	length
	mov	rax,	sys_write
	syscall
	cmp	rax,	-1
	jle	writeErr
	push	rsi
	mov	rsi,	sucWrite
	call	printString
	pop	rsi
	ret
	writeErr:
	mov	rsi,	errWrite
	call	printString
	ret

readFile:
;rdi:	file	descriptor
;rsi:	buffer
;rdx:	length
	mov	rax,	sys_read
	syscall
	cmp	rax,	-1		  ;Number of read bytes
	jle	readErr
	mov	byte[rsi+rax],	0 ;Add zero at the end
	push	rsi
	mov	rsi,	sucRead
	call	printString
	pop	rsi
	ret
	readErr:
	mov	rsi,	errRead
	call	printString
	ret

closeFile:
;rdi:	file	descriptor
	mov	rax,	sys_close
	syscall
	cmp	rax,	-1
	jle	closeErr
	push	rsi
	mov	rsi,	sucClose
	call	printString
	pop	rsi
	ret
	closeErr:
	mov	rsi,	errClose
	call	printString
	ret
