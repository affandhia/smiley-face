.include "m8515def.inc"

.def gameStarted = r15
.def smileyBox = r14 ; --> means on box 3
.def box1Opened = r13
.def box2Opened = r12
.def box3Opened = r11
.def choosenBox = r10
.def score = r9
.def boxLeft = r8
.def temp =r16 ; Define temporary variable
.def EW = r17 ; for PORTA
.def PB = r18 ; for PORTB
.def A  = r19
.def boxCounter = r23

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
	mov score, temp
	ldi boxCounter, 0 ; for box counter
	ldi temp, 2
	mov boxLeft, temp
	
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
	breq WAIT		; If so, wait
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
	ldi temp, 1
	add boxCounter, temp
	cpi boxCounter, 1
	breq PRINT_BOX_1
	cpi boxCounter, 2
	breq PRINT_BOX_2
	cpi boxCounter, 3
	breq PRINT_BOX_3
	rjmp PRINT_BOX_CLOSED
	
PRINT_BOX_1:		
	cp box1Opened, temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED
PRINT_BOX_2:		
	cp box2Opened, temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED
PRINT_BOX_3:		
	cp box3Opened, temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED

PRINT_BOX_CLOSED:
	ldi A, $FF
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE	
PRINT_BOX_OPENED: 
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

WAIT:
	ldi temp, 3
	cp gameStarted, temp
	brne NOT_FALSE
	ldi temp, 1
	mov gameStarted, temp
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi boxCounter, 0 ; for box counter
	rjmp LOADBYTE

NOT_FALSE:
	ldi temp, 2
	cp gameStarted, temp
	brne NOT_OVER
	rcall WAIT_LCD
	rcall WAIT_LCD
	rcall WAIT_LCD
	rcall WAIT_LCD
	rjmp START
NOT_OVER:
	ldi temp, 0
	cp boxLeft, temp
	breq GAME_OVER
	cp gameStarted, temp
	breq WAIT
	in temp, PIND
	in choosenBox, PIND
	cpi temp, 1 ; first box
	breq CHOOSEN1
	cpi temp, 1<<1 ; second box
	breq CHOOSEN2
	cpi temp, 2<<1 ; third box
	breq CHOOSEN3
	rjmp WAIT

CHOOSEN1:
	ldi temp, 1
	cp box1Opened, temp
	breq WAIT

	mov box1Opened, temp

	ldi temp, 1
	cp smileyBox, temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN2:
	ldi temp, 1
	cp box2Opened, temp
	breq WAIT

	mov box2Opened, temp

	ldi temp, 1<<1
	cp smileyBox, temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN3:
	ldi temp, 1
	cp box3Opened, temp
	breq WAIT

	mov box3Opened, temp

	ldi temp, 2<<1
	cp smileyBox, temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

FOUND_SMILEY:
	ldi temp, 1
	add score, temp
	rjmp GAME_START

GAME_OVER:
	rcall INIT_LCD
	ldi ZH,high(2*gameoverscreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gameoverscreen) ; Load low part of byte address into ZL
	ldi temp, 2			; 2 for game over
	mov gameStarted, temp
	rjmp LOADBYTE
	rjmp GAME_OVER

GAME_START:
	ldi temp, 0
	mov box1Opened, temp
	mov box2Opened, temp	
	mov box3Opened, temp
	ldi temp, 2<< 0b1
	mov smileyBox, temp	
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi temp, 2 ; bug: it gives 1 to temp register
	ldi A, 2  ; but on this A register, it gives 2, so we use this one
	mov boxLeft, A ; for box counter
	rjmp LOADBYTE

FALSE_ANSWER:
	ldi temp, 3
	mov gameStarted, temp
	ldi temp, 1
	sub boxLeft, temp
	rcall INIT_LCD
	ldi ZH,high(2*gamemissedbox) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamemissedbox) ; Load low part of byte address into ZL
	rjmp LOADBYTE

RESET_BOX:
	ldi temp, 0

EN_INT: ;enable intterupt
	ldi temp, 0b10000000  ;1<<INT0 | 1<<INT1 | 1<<INT2
	out PORTC, temp
	out GICR,temp
	ldi temp,0b00001010
	out MCUCR,temp
	sei
	ret

WAIT_LCD:
	ldi r20, 1
	ldi r21, 25
	ldi r22, 25
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
	.db "Find The Smiley!,. Press  Start ."
	.db 0
	
gamescreen:
	.db "Which's box?,  .    .    .  "
	.db 0

gameoverscreen:
	.db "Game Over,   ___You LOSE!"
	.db 0

gamemissedbox:
	.db "Oh No! WRONG BOX,    Try Again!"
	.db 0

gamewinscreen:
	.db "You found it!, Congrats!"
	.db 0
