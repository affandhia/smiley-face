.include "m8515def.inc"

.def gameStarted = r15
.def smileyBox = r14 ; --> means on box 3
.def temp =r16 ; Define temporary variable
.def EW = r17 ; for PORTA
.def PB = r18 ; for PORTB
.def A  = r19

; PORTB as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW	
	
.org 0x000
	rjmp START
.org 0x002
	rcall EN_INT
	tst gameStarted
	brne START
	ldi temp, 1
	mov gameStarted, temp
	rjmp GAME_START
.org 0x00D
	rjmp START

START:
	ldi temp,low(RAMEND) ; Set stack pointer to -
	out SPL,temp ; -- last internal RAM location
	ldi temp,high(RAMEND)
	out SPH,temp

	rcall INIT_LCD
	rcall INIT_LEDs
	rcall EN_INT
	
	ldi temp, 0
	mov gameStarted, temp	
	ldi temp, 3
	mov smileyBox, temp	

	ldi temp,$ff
	out DDRA,temp ; Set port A as output
	out DDRB,temp ; Set port B as output
	ldi TEMP,$00
	out DDRD,TEMP	;set PIN D TO READ

	ldi ZH,high(2*message) ; Load high part of byte address into ZH
	ldi ZL,low(2*message) ; Load low part of byte address into ZL

LOADBYTE:
	lpm				; Load byte from program memory into r0
	mov r20, r0
	tst	r0			; Check if we've reached the end of the message
	breq quit		; If so, quit
	cpi r20, 0x2C	; Check if we've met a comma char
	breq CHANGE

	ldi temp, 1
	cp gameStarted, temp
	breq PREP_PRINT_BOX
	cpi r20, $2E
	breq PRINT_SMILEY
PREP_PRINT_BOX:
	cpi r20, $2E
	breq PRINT_BOX
	mov A, r20		; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE
		
PRINT_SMILEY:
	ldi A, $C2
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE

PRINT_BOX:
	ldi A, $DB
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE	

CHANGE:
	cbi PORTA,1	; CLR RS
	ldi PB,0xC0	; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	adiw ZL,1
	rjmp LOADBYTE

QUIT: 
	ldi temp, 0
	cp gameStarted, temp
	breq QUIT
	in temp, PIND
	cpi temp, 0x01
	breq START
	rjmp QUIT

GAME_START:
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	rjmp LOADBYTE	

EN_INT: ;enable intterupt
	ldi temp, 0b10000000  ;1<<INT0 | 1<<INT1 | 1<<INT2
	out PORTC, temp
	out GICR,temp
	ldi temp,0b00001010
	out MCUCR,temp
	ldi temp, 0b00000000
	out EMCUCR, temp
	ldi temp, 0b11100000
	out GIFR, temp
	sei
	ret

WAIT_LCD:
	ldi r20, 1
	ldi r21, 69
	ldi r22, 69
CONT: 
	dec r22
	brne CONT
	dec r21
	brne CONT
	dec r20
	brne CONT
	ret

INIT_LEDs:
	ldi temp, 0x00
	out DDRC, temp
	ret

CLEAR_LEDs:
	ldi temp, 0x00
	out DDRC, temp
	out PORTC, temp
	ret

INIT_LCD:
	cbi PORTA,1 ; CLR RS
	ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1 ; CLR RS
	ldi PB,$0C ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	rcall CLEAR_LCD ; CLEAR LCD
	cbi PORTA,1 ; CLR RS
	ldi PB,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	ret

CLEAR_LCD:
	cbi PORTA,1 ; CLR RS
	ldi PB,$01 ; MOV DATA,0x01
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT:
	sbi PORTA,1 ; SETB RS
	out PORTB, A
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT_NO_DELAY:
	sbi PORTA,1 ; SETB RS
	out PORTB, A
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	ret

message:
	.db "Find The Smiley,. Press  Start ."
	.db 0
	
gamescreen:
	.db "Which's box?,  .    .    .  "
	.db 0
