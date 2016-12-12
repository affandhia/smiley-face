.include "m16def.inc"

.def gameStarted = r15
.def smileyBox = r14
.def box1Opened = r13
.def box2Opened = r12
.def box3Opened = r11
.def choosenBox = r10
.def score = r9
.def boxLeft = r8
.def temp = r16
.def EW = r17 
.def PB = r18 
.def A  = r19
.def boxCounter = r23
.def timerTemp = r24
.def timerCounter = r25
	

; Game state on gameStarted
; 0 : game is not started
; 1 : game is running
; 2 : game is over
; 3 : user wrongly choosed the box
; 4 : user win the game (found the smiley)
; 5 : win message had been shown
	
.org 0x000
	rjmp START
.org 0x004
	rcall EN_INT
	ldi temp,0
	cp gameStarted,temp
	brne START
	ldi temp,1
	mov gameStarted,temp
	rjmp GAME_START

.org $00E
	reti

.org $012
	rjmp ISR_TOV0

; TIMER INTERRUPT ==================
ISR_TOV0:
	ldi timerTemp, 1
	add timerCounter, timerTemp
	in timerTemp,PORTC
	tst timerTemp
	brne ISR_TOV0_NEXT_STEP

	rcall STOP_TIMER0
		
	jmp GAME_OVER
ISR_TOV0_NEXT_STEP:
	cpi timerCounter, 5
	brge DECREASE_TIME
	reti

DECREASE_TIME:
	in timerTemp,PORTC	; read Port C
	lsl timerTemp			; shift left timer.
	out PORTC,timerTemp	; write Port C
	ldi timerCounter, 0
	reti

STOP_TIMER0:
	ldi r16,0<<CS02 	
	out TCCR0,r16	; set clock source
	ret

START_TIMER0:
	ldi r16,1<<CS02
	out TCCR0,r16	; set clock source
	ret
	
START_KEYPAD_ext:	; branch extension
	jmp START_KEYPAD

START:
	; ******** Set stack pointer to last internal RAM location
	ldi temp,low(RAMEND) 
	out SPL,temp ; 
	ldi temp,high(RAMEND)
	out SPH,temp
	; ********
	
	ldi temp, 1<<CS11	; set source clock prescales at clock/8
	out TCCR1B,temp				; set timer
	ldi temp,1<<TOV0 | 1<<OCF1B
	out TIFR,temp		; Interrupt if overflow in Timer0 and compare Timer1 matched to T1B value
	; ******** Set compared T1B value
	ldi temp,0xf3
	out OCR1BL,r16		
	ldi temp,0xf2
	out OCR1BH,r16
	; ********
	ldi temp, 1<<TOIE0 | 1<<OCIE1B
	out TIMSK,temp		; Enable Timer0 and CompareT1B

	ldi temp,$ff
	out DDRA,temp ; Set port A as output LCD
	out DDRC,temp ;	
	ldi temp,$00
	out DDRB,temp
	
	rcall INIT_LCD
	rcall EN_INT
	rcall STOP_TIMER0

	ldi temp,0
	mov gameStarted,temp
	mov score,temp
	ldi boxCounter,0 ; for box counter
	ldi timerCounter, 0
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
	lsl boxCounter
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
	ldi temp,6
	cp gameStarted,temp
	brne NO_INPUT
	jmp INPUT_NPM 
GAME_WIN_ext:
	jmp GAME_WIN

NO_INPUT:
	ldi temp,5
	cp gameStarted,temp
	breq GAME_START_ext
	ldi temp,4
	cp gameStarted,temp
	breq GAME_WIN_ext
	ldi temp,2
	cp gameStarted,temp
	breq SUBMIT_SCORE_ext
	;rcall WAIT_LCD
	;rcall WAIT_LCD
	;rcall WAIT_LCD
	;rcall WAIT_LCD
	;rjmp START
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
	rcall START_TIMER0
	rjmp WAIT

SUBMIT_SCORE_ext:
	jmp SUBMIT_SCORE

GAME_START_ext:
	jmp GAME_START

CHOOSEN1:
	ldi temp,1
	cp box1Opened,temp
	breq WAIT
	
	mov box1Opened,temp
	
	rcall STOP_TIMER0	

	ldi temp,1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN2:
	ldi temp,1
	cp box2Opened,temp
	breq WAIT

	mov box2Opened,temp

	rcall STOP_TIMER0	

	ldi temp,1<<1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

CHOOSEN3:
	ldi temp,1
	cp box3Opened,temp
	breq WAIT_ext

	mov box3Opened,temp

	rcall STOP_TIMER0	

	ldi temp,2<<1
	cp smileyBox,temp
	breq FOUND_SMILEY
	rjmp FALSE_ANSWER

WAIT_ext:
	jmp WAIT

GAME_OVER:
	rcall INIT_LCD
	ldi ZH,high(2*gameoverscreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gameoverscreen) ; Load low part of byte address into ZL
	ldi temp,2			; 2 for game over
	mov gameStarted,temp
	rjmp LOADBYTE

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

INIT_SCORE:
	ldi A, 0x00
	ST Z, A
SUBMIT_SCORE:
	ldi ZH, 0x00
	ldi ZL, 0x60
	LD temp, Z
	cpi temp, 0xff
	breq INIT_SCORE
	cp temp, score
	brlo NEW_SCORE
	rjmp START

NEW_SCORE:
	rcall INIT_LCD
	ldi ZH,high(2*gamesubmitscore) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamesubmitscore) ; Load low part of byte address into ZL
	ldi temp,6			; 2 for game over
	mov gameStarted,temp
	ldi XH, 0x00
	ldi XL, 0x60
	ST X, score
	ldi XH, 0x00
	ldi XL, 0x6A
LOOP_RENEW:
	ldi temp, 0x00
	ST X, temp
	adiw X, 1
	cpi XL, 0x74
	brne LOOP_RENEW
	rjmp LOADBYTE

INPUT_NPM:
	ldi XH, 0x00
	ldi XL, 0x6A
LOOP_INPUT:
	rcall START_KEYPAD
	ldi temp, 0xf0
	cp r0, temp
	breq START_ext
	mov A, r0
	rcall WRITE_TEXT
	ST X, r0
	adiw X, 1
	cpi XL, 0x74
	brne LOOP_INPUT
	rjmp START

START_ext:
	jmp START

GAME_START:
	ldi temp,0
	mov box1Opened,temp
	mov box2Opened,temp	
	mov box3Opened,temp

	in timerTemp, TCNT1H
	andi timerTemp, 0x03
	
	cpi timerTemp, 0x00
	breq SET_SMILEY_TO_1
	cpi timerTemp, 0x01
	breq SET_SMILEY_TO_2
	cpi timerTemp, 0x02
	breq SET_SMILEY_TO_3
	brne SET_SMILEY_TO_DEFAULT
SET_SMILEY_TO_1:
	ldi temp,1
	mov smileyBox,temp
	rjmp GAME_START_NEXT
SET_SMILEY_TO_2:
	ldi temp,1<<1
	mov smileyBox,temp
	rjmp GAME_START_NEXT
SET_SMILEY_TO_3:
	ldi temp,2<<1
	mov smileyBox,temp
	rjmp GAME_START_NEXT
SET_SMILEY_TO_DEFAULT:
	ldi temp,1
	mov smileyBox,temp
	rjmp GAME_START_NEXT

GAME_START_NEXT:
	rcall INIT_LCD
	ldi ZH,high(2*gamescreen) ; Load high part of byte address into ZH
	ldi ZL,low(2*gamescreen) ; Load low part of byte address into ZL
	ldi temp,2 ; bug: it gives 1 to temp register
	ldi A,2  ; but on this A register,it gives 2,so we use this one
	mov boxLeft,A ; for box counter
	ldi temp,1
	mov boxCounter,temp
	mov gameStarted,temp
	ldi temp, 0xff
	out PORTC, temp
	rcall START_TIMER0

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

WATI_10ms:
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

gamesubmitscore:
	.db "New Highscore!!!,NPM:"
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
	rcall WATI_10ms
	ldi ZH,HIGH(2*KeyTable) ; Z is pointer to key code table
	ldi ZL,LOW(2*KeyTable)
	; read column 1
	;ldi rmp,0b01111111 ; PB6 = 0
	;out pKeyOut,rmp
	;in rmp,pKeyInp ; read input line
	;ori rmp,0b11110000 ; mask upper bits
	;cpi rmp,0b11111111 ; a key in this column pressed?
	;brne KeyRowFound ; key found
	;adiw ZL,4 ; column not found, point Z one row down
	; read column 1
	ldi rmp,0b00111111 ; PB6 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read input line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column pressed?
	brne KeyRowFound ; key found
	adiw ZL,4 ; column not found, point Z one row down
	; read column 2
	ldi rmp,0b01011111 ; PB5 = 0
	out pKeyOut,rmp
	in rmp,pKeyInp ; read again input line
	ori rmp,0b11110000 ; mask upper bits
	cpi rmp,0b11111111 ; a key in this column?
	brne KeyRowFound ; column found
	adiw ZL,4 ; column not found, another four keys down
	; read column 3
	ldi rmp,0b01101111 ; PB4 = 0
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
	ret
NoKey:
	rjmp ReadKey ; no key pressed
;
; Table for code conversion
;

KeyTable:
;.DB 0xff,0xf0,0x0f,0x00 ; fourth column, keys left, right, down und up
.DB 0x33,0x36,0x39,0xF0 ; third column, keys #, 9, 6 und 3
.DB 0x32,0x35,0x38,0x30 ; second column, keys 0, 8, 5 und 2
.DB 0x31,0x34,0x37,0xF0 ; first column, keys *, 7, 4 und 1

KeyProc:
	ret



