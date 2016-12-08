.include "m8515def.inc"

.def temp =r16 ; Define temporary variable
.def EW = r17 ; for PORTA
.def PB = r18 ; for PORTB
.def A  = r19

; PORTB as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW

START:
ldi temp,low(RAMEND) ; Set stack pointer to -
out SPL,temp ; -- last internal RAM location
ldi temp,high(RAMEND)
out SPH,temp

rcall INIT_LCD

ldi temp,$ff
out DDRA,temp ; Set port A as output
out DDRB,temp ; Set port B as output

ldi ZH,high(2*message) ; Load high part of byte address into ZH
ldi ZL,low(2*message) ; Load low part of byte address into ZL

LOADBYTE:
lpm ; Load byte from program memory into r0

tst r0 ; Check if we've reached the end of the message
breq QUIT ; If so, quit

mov A, r0 ; Put the character onto Port B
rcall WRITE_TEXT
adiw ZL,1 ; Increase Z registers
rjmp LOADBYTE

QUIT: rjmp QUIT

WAIT_LCD:
ldi r20, 1
ldi r21, 69
ldi r22, 69
CONT: dec r22
brne CONT
dec r21
brne CONT
dec r20
brne CONT
ret

INIT_LCD:
cbi PORTA,1 ; CLR RS
ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
out PORTB,PB
sbi PORTA,0 ; SETB EN
cbi PORTA,0 ; CLR EN
rcall WAIT_LCD
cbi PORTA,1 ; CLR RS
ldi PB,$0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
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

message:
.db "Find The Smiley,Press Start"
.db 0
