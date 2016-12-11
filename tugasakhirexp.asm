.include "m16def.inc"

.def gameStarted = r15
.def smileyBox = r14 ; --> means on box 3
.def box1Opened = r13
.def box2Opened = r12
.def box3Opened = r11
.def choosenBox = r10
.def score = r9
.def boxLeft = r8
.def temp =r16 ; Define temporary variable
.def EW = r17 ; for PORTAD
.def PB = r18 ; for PORTBA
.def A  = r19
.def boxCounter = r23

; PORTBA as DATA
; PORTD,4 as EN
; PORTAD.1 as RS
; PORTAD.2 as RW	

; Game state on gameStarted
; 0 : game is not started
; 1 : game is running
; 2 : game is over
; 3 : user wrongly choosed the box
; 4 : user win the game (found the smiley)
	
.org 0x000
	rjmp START
.org 0x004
	rcall EN_INT
	ldi temp,0
	cp gameStarted,temp
	brne START
	ldi temp,1
	mov gameStarted,temp
	rjmp START_KEYPAD_ext

START_KEYPAD_ext:
	jmp START_KEYPAD

START:
	ldi temp,low(RAMEND) ; Set stack pointer to -
	out SPL,temp ; -- last internal RAM location
	ldi temp,high(RAMEND)
	out SPH,temp
	
	rcall INIT_LCD
	rcall EN_INT

	ldi temp,$ff
	out DDRA,temp ; Set port A as output
	out DDRB,temp ;
	ldi temp,$00
	out DDRC,temp

	
	
	ldi temp,0
	mov gameStarted,temp
	mov score,temp
	ldi boxCounter,0 ; for box counter
	ldi temp,2
	mov boxLeft,temp
	
	


	ldi ZH,high(2*message) ; Load high part of byte address into ZH
	ldi ZL,low(2*message) ; Load low part of byte address into ZL

LOADBYTE:
	lpm				; Load byte from program memory into r0
	mov r20,r0
	tst	r0			; Check if we've reached the end of the message
	breq WAIT		; If so,wait
	cpi r20,0x2C	; Check if we've met a comma char
	breq CHANGE_ext
	
	cpi r20,$2E
	breq PRINT_SMILEY

	mov A,r20		; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE
		
PRINT_SMILEY:
	ldi temp,4
	cp gameStarted,temp
	brne PRINT_SMILEY_NOT_WIN
	cp boxCounter,choosenBox
	brne PRINT_BOX_NOT_WIN

PRINT_SMILEY_NOT_WIN:
	ldi temp,1
	cp gameStarted,temp
	breq PRINT_BOX_NOT_WIN
	ldi temp,3
	cp gameStarted,temp
	breq PRINT_BOX_NOT_WIN
	ldi temp,2
	cp gameStarted,temp
	breq PRINT_BOX_NOT_WIN
	ldi A,$C2
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE

PRINT_BOX:
	cp smileyBox,boxCounter
	breq PRINT_SMILEY

PRINT_BOX_NOT_WIN:
	ldi temp,1
	cpi boxCounter,1
	breq PRINT_BOX_1
	cpi boxCounter,1<<1
	breq PRINT_BOX_2
	cpi boxCounter,2<<1
	breq PRINT_BOX_3

	rjmp PRINT_BOX_CLOSED

PRINT_BOX_1:		
	cp box1Opened,temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED
PRINT_BOX_2:		
	cp box2Opened,temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED
PRINT_BOX_3:		
	cp box3Opened,temp
	breq PRINT_BOX_OPENED
	rjmp PRINT_BOX_CLOSED

PRINT_BOX_CLOSED:
	lsl boxCounter
	ldi A,$FF
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE	
PRINT_BOX_OPENED:
	lsl boxCounter 
	ldi A,$DB
	rcall WRITE_TEXT
	adiw ZL,1		; Increase Z registers
	brne LOADBYTE	

CHANGE_ext:
	rjmp CHANGE

WAIT:
	ldi temp,3
	cp gameStarted,temp
	brne NOT_FALSE
	ldi temp,1
	mov gameStarted,temp
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi boxCounter,1 ; for box counter
	rjmp LOADBYTE

NOT_FALSE:
	ldi temp,5
	cp gameStarted,temp
	breq GAME_START_ext
	ldi temp,4
	cp gameStarted,temp
	breq GAME_WIN
	ldi temp,2
	cp gameStarted,temp
	brne NOT_OVER
	rcall WAIT_LCD
	rcall WAIT_LCD
	rcall WAIT_LCD
	rcall WAIT_LCD
	rjmp START
NOT_OVER:
	ldi temp,0
	cp boxLeft,temp
	breq GAME_OVER
	cp gameStarted,temp
	breq WAIT
	in temp,PIND
	in choosenBox,PIND
	cpi temp,1 ; first box
	breq CHOOSEN1
	cpi temp,1<<1 ; second box
	breq CHOOSEN2
	cpi temp,2<<1 ; third box
	breq CHOOSEN3
	rjmp WAIT

GAME_START_ext:
	rjmp GAME_START

CHOOSEN1:
	ldi temp,1
	cp box1Opened,temp
	breq WAIT

	mov box1Opened,temp

	ldi temp,1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN2:
	ldi temp,1
	cp box2Opened,temp
	breq WAIT

	mov box2Opened,temp

	ldi temp,1<<1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN3:
	ldi temp,1
	cp box3Opened,temp
	breq WAIT

	mov box3Opened,temp

	ldi temp,2<<1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

FOUND_SMILEY:
	ldi temp,1
	add score,temp
	ldi temp,4
	mov gameStarted,temp
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi temp,1
	mov boxCounter,temp
	rjmp LOADBYTE

GAME_WIN:
	ldi temp,5
	mov gameStarted,temp
	rcall INIT_LCD
	ldi ZH,high(2*gamewinscreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamewinscreen) ; Load low part of byte address into ZL
	rjmp LOADBYTE

GAME_OVER:
	rcall INIT_LCD
	ldi ZH,high(2*gameoverscreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gameoverscreen) ; Load low part of byte address into ZL
	ldi temp,2			; 2 for game over
	mov gameStarted,temp
	rjmp LOADBYTE
	rjmp GAME_OVER

GAME_START:
	ldi temp,0
	mov box1Opened,temp
	mov box2Opened,temp	
	mov box3Opened,temp
	ldi temp,2<< 0b1
	mov smileyBox,temp	
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi temp,2 ; bug: it gives 1 to temp register
	ldi A,2  ; but on this A register,it gives 2,so we use this one
	mov boxLeft,A ; for box counter
	ldi temp,1
	mov boxCounter,temp
	mov gameStarted,temp
	rjmp LOADBYTE

FALSE_ANSWER:
	ldi temp,3
	mov gameStarted,temp
	ldi temp,1
	sub boxLeft,temp
	rcall INIT_LCD
	ldi ZH,high(2*gamemissedbox) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamemissedbox) ; Load low part of byte address into ZL
	rjmp LOADBYTE

CHANGE:
	cbi PORTD,5	; CLR RS
	ldi PB,0xC0	; MOV DATA,0x38 --> 8bit,2line,5x7
	out PORTA,PB
	sbi PORTD,4	; SETB EN
	cbi PORTD,4	; CLR EN
	rcall WAIT_LCD
	adiw ZL,1
	rjmp LOADBYTE

EN_INT: ;enable intterupt
	ldi temp,0b10000000  ;1<<INT0 | 1<<INT1 | 1<<INT2
	out GICR,temp
	ldi temp,0b00001010
	out MCUCR,temp
	sei
	ret

WAIT_LCD:
	ldi r20,1
	ldi r21,25
	ldi r22,25
CONT: 
	dec r22
	brne CONT
	dec r21
	brne CONT
	dec r20
	brne CONT
	ret

CLEAR_LEDs:
	ldi temp,0x00
	out DDRC,temp
	out PORTC,temp
	ret

INIT_LCD:
	cbi PORTD,5	; CLR RS
	ldi PB,0x38	; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTA,PB
	sbi PORTD,4	; SETB EN
	cbi PORTD,4	; CLR EN
	rcall WAIT_LCD
	cbi PORTD,5	; CLR RS
	ldi PB,$0C	; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTA,PB
	sbi PORTD,4	; SETB EN
	cbi PORTD,4	; CLR EN
	rcall WAIT_LCD
	rcall CLEAR_LCD ; CLEAR LCD
	cbi PORTD,5	; CLR RS
	ldi PB,$06	; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTA,PB
	sbi PORTD,4	; SETB EN
	cbi PORTD,4	; CLR EN
	rcall WAIT_LCD
	ret



CLEAR_LCD:
	cbi PORTD,5 ; CLR RS
	ldi PB,$01 ; MOV DATA,0x01
	out PORTA,PB
	sbi PORTD,4 ; SETB EN
	cbi PORTD,4 ; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT:
	sbi PORTD,5 ; SETB RS
	out PORTA,A
	sbi PORTD,4 ; SETB EN
	cbi PORTD,4 ; CLR EN
	rcall WAIT_LCD
	ret

WRITE_TEXT_NO_DELAY:
	sbi PORTD,5 ; SETB RS
	out PORTA,A
	sbi PORTD,4 ; SETB EN
	cbi PORTD,4 ; CLR EN
	ret

message:
	.db "Find The Smiley!,. Press  Start ."
	.db 0
	
gamescreen:
	.db "Which's box?,  .    .    .  "
	.db 0

gameoverscreen:
	.db "    YOU LOSE    , No more choice "
	.db 0

gamemissedbox:
	.db "Oh No! WRONG BOX,    Try Again!"
	.db 0

gamewinscreen:
	.db "You found it . !,Take d' next one"
	.db 0


START_KEYPAD:
;
; Init keypad-I/O
;
.DEF rmp = R16 ; define a multipurpose register
; define ports
.EQU pKeyOut = PORTB ; Output and Pull-Up-Port
.EQU pKeyInp = PINB  ; read keypad input
.EQU pKeyDdr = DDRB  ; data direction register of the port
; Init-routine
InitKey:
	ldi rmp,0b11110000 ; data direction register column lines output
	out pKeyDdr,rmp    ; set direction register
	ldi rmp,0b00001111 ; Pull-Up-Resistors to lower four port pins
	out pKeyOut,rmp    ; to output port

;
; Check any key pressed
;
AnyKey:
	ldi rmp,0b00001111 ; PB4..PB6=Null, pull-Up-resistors to input lines
	out pKeyOut,rmp    ; of port pins PB0..PB3
	in rmp,pKeyInp     ; read key results
	ori rmp,0b11110000 ; mask all upper bits with a one
	cpi rmp,0b11111111 ; all bits = One?
	breq NoKey         ; yes, no key is pressed

;
; Identify the key pressed
;
ReadKey:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 40 000 cycles
; 5ms at 8.0 MHz

    ldi  r18, 52
    ldi  r19, 242
L1: dec  r19
    brne L1
    dec  r18
    brne L1
    nop

	ldi ZH,HIGH(2*KeyTable) ; Z is pointer to key code table
	ldi ZL,LOW(2*KeyTable)
	; read column 1
	ldi rmp,0b01111111 ; PB6 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read input line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column pressed?
	brne KeyRowFound ; key found
	adiw ZL,4 ; column not found, point Z one row down
	; read column 1
	ldi rmp,0b10111111 ; PB6 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read input line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column pressed?
	brne KeyRowFound ; key found
	adiw ZL,4 ; column not found, point Z one row down
	; read column 2
	ldi rmp,0b11011111 ; PB5 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read again input line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column?
	brne KeyRowFound ; column found
	adiw ZL,4 ; column not found, another four keys down
	; read column 3
	ldi rmp,0b11101111 ; PB4 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read last line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column?
	breq NoKey ; unexpected: no key in this column pressed
KeyRowFound: ; column identified, now identify row
	lsr rmp ; shift a logic 0 in left, bit 0 to carry
	brcc KeyFound ; a zero rolled out, key is found
	adiw ZL,1 ; point to next key code of that column
	rjmp KeyRowFound ; repeat shift
KeyFound: ; pressed key is found 
	lpm ; read key code to R0
	rcall KeyProc ; countinue key processing
	rjmp ReadKey
NoKey:
	rjmp ReadKey ; no key pressed
;
; Table for code conversion
;

KeyTable:
.DB 0xff,0xf0,0x0f,0x00 ; fourth column, keys left, right, down und up
.DB 0x03,0x06,0x09,0x0B ; third column, keys #, 9, 6 und 3
.DB 0x02,0x05,0x08,0x00 ; second column, keys 0, 8, 5 und 2
.DB 0x01,0x04,0x07,0x0A ; first column, keys *, 7, 4 und 1

KeyProc:
	out PORTC, r0
	ret

NoKeyPressed:
	ldi temp, 0x00
	out PORTC, temp
	ret
