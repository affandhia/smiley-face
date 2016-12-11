.include "m8515def.inc"
.def sem =r18 
.def button = r19

; LED => PORT C

rjmp INIT


WAIT:
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



READ_BUTTON:
in button, PIND
cpi button, 0x00
breq READ_BUTTON
ret


TEST_LED:
ldi sem,0x01 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x02 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x04 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x08 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x10 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x20 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x40 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0x80 
out PORTC,sem ; Update LEDS
rcall WAIT
ret


TEST_LED2:
ldi sem,0x0f 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0xf0 
out PORTC,sem ; Update LEDS
rcall WAIT


ldi sem,0x0f 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0xf0 
out PORTC,sem ; Update LEDS
rcall WAIT


ldi sem,0x0f 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0xf0 
out PORTC,sem ; Update LEDS
rcall WAIT


ldi sem,0x0f 
out PORTC,sem ; Update LEDS
rcall WAIT

ldi sem,0xf0 
out PORTC,sem ; Update LEDS
rcall WAIT

ret


INIT:
ldi	sem,low(RAMEND)
out	SPL,sem	;init Stack Pointer		
ldi	sem,high(RAMEND)
out	SPH,sem

ser sem ; load $FF to sem
;ldi sem, 0xFF
out DDRC,sem ; Set PORTB to output
ldi sem, 0b00000000
out DDRD,sem


MAIN:
rcall READ_BUTTON
cpi button, 0x11
breq TEST_LED
cpi button, 0x02
breq TEST_LED2
rjmp MAIN





