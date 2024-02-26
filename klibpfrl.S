@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Klib-pfrl (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								February 23rd, 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

.ifndef KLIB_PFRL_ARM_ASSEMBLY_
.set KLIB_PFRL_ARM_ASSEMBLY_, 1

.include "../src/klibio.S"

.data

@ Array of possible keypad buttons, with -1 appended for no button pressed
keys: .word 0,7,4,1,0xF,8,5,2,0xE,9,6,3,0xD,0xC,0xB,0xA,-1

.text
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ getKeypadRaw
@ Enable seven-segment display in default mode
@
@	No parameters
@
@	r0		return -> 16-bit number to indicate pressed button(s)
@
@ Written by Koby Miller
@ Last modified: February 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
getKeypadRaw:
	
	push {r1,r2,r3,r4,lr}
	mov r3, #0 @ iterator
	mov r4, #0 @ number to shift and store pressed keys in 
	getKeypadRawLoop:

		mov r1, #0 @ argument to write to top row
		mov r2, #1 @ assign a 1
		lsl r2, r3 @ shift that number 1 over by iterator, so that each column is hit

		mvn r2, r2 @ invert that shifted 1

		@ Write to PMOD B top row
		bl pmodWrite
		
		@ Delay between write and read
		bl dummyTimer
		
		@ Read from PMOD B bottom row
		mov r1, #1
		bl pmodRead
		
		@ move over r4 to store next 4-bit value corresponding to row
		lsl r4, #4

		@ add that 4-bit value to r4
		orr r4, r4, r0
		
	add r3, r3, #1 @ increment
	cmp r3, #4 				@ for loop test
	bmi getKeypadRawLoop 	@ for loop test
	
	@ mask off
	mov r3, #0xFFFF

	@ invert and return
	mvn r4, r4
	and r4, r3
	mov r0, r4
	
	pop {r1,r2,r3,r4,lr}
	@ 0,7,4,1,F,8,5,2,E,9,6,3,D,C,B,A
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ getKeypadRaw
@ Enable seven-segment display in default mode
@
@	No parameters
@
@	r0		return -> value of pressed keypad button, -1 when no buttons are pressed
@
@ Written by Koby Miller
@ Last modified: February 22nd, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
getKeypad:

	push {r1,r2,lr}
	
	@ get 16-bit number from keypad
	bl getKeypadRaw
	
	mov r2, #0 @ zero counter
	
	getKeypadLoop:
		
		@ check until a 1 is found in 16-bit number
		mov r1, r0
		and r1, r1, #1
		lsr r0, #1

		@ break getKeypadLoop if at 16
		cmp r2, #16
		beq leaveGetKeypad
	cmp r1, #1
	addne r2, r2, #1 @ add to counter
	bne getKeypadLoop
	
	leaveGetKeypad:

	@ index key array
	ldr r1, =keys
	ldr r0, [r1,r2,lsl #2]

	pop {r1,r2,lr}

bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ EoF
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.endif 