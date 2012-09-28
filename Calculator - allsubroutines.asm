		
		CPU	5307
		include q:\eng\ece\Coldfire\coldfire.asm

;INSTANTIATIONS		
PROGRAM equ 	$10200000
OPERAND equ 	$10210000
BUFFER  equ 	$10220000
BUFFER2 equ 	$10300000
STACK	equ		$10350000
TEXT	equ 	$10400000
CR 		equ 	$0D
LF 		equ 	$0A

		org		TEXT
PROMPT	dc.b 	"0. Return to Monitor",CR,LF
		dc.b 	"1. Clock Display",CR,LF
		dc.b 	"2. Enter Clock Mode",CR,LF
		dc.b 	"3. Enter Calculator Mode",CR,LF
		dc.b 	"Please enter a selection...",CR,LF,$0
		
C_PRMT	dc.b 	"Please enter the operation you want to perform:",CR,LF
		dc.b 	"Addition       (Enter '+')",CR,LF
		dc.b 	"Subtraction    (Enter '-')",CR,LF
		dc.b 	"Multiplication (Enter '*')",CR,LF
		dc.b 	"Square Subtract(Enter '^', will do [A^2-B])",CR,LF
		dc.b	"Any other text or character will return",CR,LF
		dc.b	"you to the main menu",CR,LF,$0

NEGATIV	dc.b	"-",$0			;creating label for a negative sign

LRG_ERR	dc.b	"Input numbers are too large (from 0 to 9999 only).",CR,LF,$0
		
NUM_ERR	dc.b	"Invalid input, try again.",CR,LF,$0

N1_PRMT	dc.b	"Input 1st number please (0 to 9999) or [q]uit: ",CR,LF,$0
N2_PRMT	dc.b	"Input 2nd number please (0 to 9999) or [q]uit: ",CR,LF,$0		

		org		PROGRAM
		lea 	STACK,a7 	;initialize stack

MENU	lea		PROMPT,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		
		lea		BUFFER,A1	;LOADS BUFFER INTO A1
		bsr.w	in_string
		bsr.w 	out_crlf
		bsr.w 	out_crlf 	;go to next linee
		
		clr		D5
		move.b	(A1),D5
		
		cmp.l	#$30,D5		;comparing hex value of 0 to input
		beq		EXIT		;if equal, go to exit label
		cmp.l	#$31,D5		;comparing hex value of 1 to input
		beq		IN_ERR     	;if equal, go to invalid input (IN_ERR label)
		cmp.l	#$32,D5		;comparing hex value of 2 to input
		beq		IN_ERR     	;if equal, go to invalid input (IN_ERR label)
		cmp.l	#$33,D5		;comparing hex value of 3 to input
		beq		CALC        ;if equal, go to our calculator
			
		bra		IN_ERR		;if anything else is input, we will go to the invalid input (IN_ERR label)		

		
IN_ERR	lea		NUM_ERR,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		bra		MENU 		;go to menu
		
INV_NUM	lea		NUM_ERR,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		bra		CALC;		;Also, returns to calculator after message printed

BIG_NUM	lea		LRG_ERR,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		bra		CALC;		;Also, returns to calculator after message printed

check  	cmp		#9999,D3	;subroutine checking input against decimal 9999
		bgt		BIG_NUM		;goes to our BIG_NUM label
		rts
		
OUTPUT	bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;goes to next line
		bsr.w 	out_crlf 	;goes to next line again
		rts
		
EXIT	move.l	#0,D0		;our exit label
		Trap	#15	

; Calculator.asm
; This module includes the code which has our mathematical subroutines and 
; selection statements which determine which operation to use and to then
; call that subroutine appropriately. It also includes our seperate functions
; for taking inputted numerical values for the calculator.

CALC	jsr 	INPUT

OPER    lea		C_PRMT,A1 	;points to start of our calc message
		bsr.w 	out_string 	;prints our calculator message
		bsr.w 	out_crlf 	;goes to next line
		
		lea		BUFFER,A1	;LOADS BUFFER INTO A1
		bsr.w	in_string	;takes an input (we will not comment the calling of in_string anymore)
		bsr.w 	out_crlf	;go to next line (we will not comment the calling of out_crlf)
		bsr.w 	out_crlf 	
		
		clr		D5			;clears D5
		move.b	(A1),D5		;moves start stack A1 into D5
		
		cmpi.l	#$2B,D5		;comparing hex value of '+' to input
		beq		PLUS        ;if equal, go to our addition label
		cmpi.l	#$2D,D5     ;comparing hex value of '-' to input
		beq		MINUS       ;if equal, go to our subtraction label
		cmpi.l	#$2A,D5     ;comparing hex value of '*' to input
		beq		MULTI       ;if equal, go to our multiply label
		cmpi.l	#$5E,D5     ;comparing hex value of '^' to input
		beq		SQR         ;if equal, go to our square label
				
		bra		MENU		;if anything else is input, we will go to the main menu

MINUS 	;jsr		INPUT		;calling our input subroutine
		cmp		D4,D7  		;compare numbers to see if 2nd larger than first
		bgt		MINUS2		;branch if D4 larger than D7 greater than to our MINUS2
		sub.l	D7,D4		;if D4 larger than D7, then sub D7 from D4 and store in D4		
		move.l	D4,D3		;moving our resulting number into D3
		
		jsr		BIN2DEC		;calling our BIN2DEC for conversion
		jsr		OUTPUT		;calling our output subroutine
		bra		CALC		;goes to our CALC label

MINUS2	sub.l	D4,D7		;subs D4 from D7 and store in D4	
		move.l	D7,D3       ;moving our resulting number into D3
		jsr		check
		
		lea		NEGATIV,A1	;appends negative symbol to A1 for output purposes
		bsr.w 	out_string 	;prints the message
		
		jsr		BIN2DEC		;calling our BIN2DEC for conversion
		jsr		OUTPUT      ;calling our output subroutine
		bra		CALC        ;goes to our CALC label

PLUS	;jsr		INPUT		;calling our input subroutine
		add.l	D4,D7		;adds
		move.l	D7,D3
		
		jsr		check		;calls our checking sub
		jsr		BIN2DEC		;calling our BIN2DEC for conversion
		jsr		OUTPUT      ;calling our output subroutine
		bra		CALC        ;goes to our CALC label

MULTI	;jsr		INPUT		;calling our input subroutine
		mulu.l	D4,D7		;multiply D4 by D7
		move.l	D7,D3       ;store D7 in D3
		jsr		check		;calling our check subroutine
		jsr		BIN2DEC		;calling our BIN2DEC for conversion
		jsr		OUTPUT      ;calling our output subroutine
		bra		CALC        ;goes to our CALC label

SQR		;jsr		INPUT
		mulu.l	D4,D4		;square D4
		sub.l 	D7,D4		;subs D7 from D4 and store in D7
		
		move.l	D4,D3		; move result to  D3
		jsr		check
		
		jsr		BIN2DEC		; covert result to ascii
		jsr		OUTPUT		; output the result
		bra		CALC		; branch back to the start of the calculator to ensure continuity of the calculator		

NMBR_1	lea		BUFFER,A1	
		bsr.w	in_string	
		bsr.w 	out_crlf 	
		bsr.w 	out_crlf 			
		move.b	(A1),D3		
		cmp		#$71,D3		;exit on (HEX) 'q'
		beq		CALC
		cmp		#$51,D3		;exit on capital Q entry
		beq		CALC		
		jsr		DEC2BIN
		move.l	D3,D4		;using D4 as calc input for number 1
		rts
		
NMBR_2	lea		BUFFER,A1
		bsr.w	in_string
		bsr.w 	out_crlf 	
		bsr.w 	out_crlf 			
		move.b	(A1),D3		
		cmp		#$71,D3		;exit on (HEX) 'q'
		beq		CALC
		cmp		#$51,D3		;exit on capital Q entry
		beq		CALC	
		jsr		DEC2BIN
		move.l	D3,D7		;using D7 as calc input for number 2	
		rts		

;DEC2BIN.asm
;This subroutine simply converts ASCII to decimal for calculation purposes
;or for use in other subroutines		
		
DEC2BIN	move.l 	D1,-(A7)	;placing D1, D2 and A1 on the stack
		move.l 	D2,-(A7)
		move.l 	A1,-(A7)
		
		clr 	D0			;making sure both D0 and D3 are cleared
		clr		D3
		
		move.l	#10,D0		;moving decimal ten into D0
		
LOOP1	mulu.l	D0,D3		;multipling D3 by decimal 10
		move.b	(A1)+,D2	;putting the first number on the A1 stack into D2
		
		sub.l	#$30,D2		;subtracting hex 30 from D2s new value to get the decimal number
		
		cmp		#9,D2		
		bhi		FIN			;exiting!
		
		add.l	D2,D3		;otherwise ADDING D2 to D3
		
		tst.b	(A1)		;comparing A1 to zero 
		bne		LOOP1
		
		move.l 	(A7)+,A1	;removing A1, D2 and D1 from the stack
		move.l 	(A7)+,D2
		move.l 	(A7)+,D1
		
		rts
		
FIN		clr D3
		move.l	#$90,D3		;Set D3 to check for error 
		move.l 	(A7)+,A1	;removing A1, D2 and D1 from the stack
		move.l 	(A7)+,D2
		move.l 	(A7)+,D1
		
		rts

;BIN2DEC.asm
;This subroutine simply converts decimal to ASCII for calculation purposes
;or for use in other subroutines	

BIN2DEC	move.l 	D0,-(A7)	;placing D0, D2 and A1 on the stack
		move.l 	D2,-(A7)
		
		lea		BUFFER2,A2	;Loading the buffer into A2
		
		move.l	#10,D0		;moving decimal ten into D0
		move.b	#0,-(A2)	;putting a decimal zero onto the stack A2


LOOP2	remu.l	D0, D2:D3	;D2 = D3 mod D0(decimal 10), D2 is storing the remainder
		divu.l	D0,D3		;actually dividing D3 by D0
		and.l	#$0000ffff,D3	;bit comparison with D3
		add.l	#$30,D2		;adding hex 30 to get ascii
		move.b	D2,-(A2)	;putting D2 onto the stack
		tst.l	D3			;checking if input empty
		bne		LOOP2		;while not empty, keep looping (LOOP2)
		movea.l	A2,A1		;moving A2 to A1
		move.l 	(A7)+,D2	;deallocating the stack
		move.l 	(A7)+,D0
		rts
		
INPUT	lea 	N1_PRMT,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		
		jsr		NMBR_1		;goes to our NMBR_1 label
		cmp		#9999,D4	;comparing taken in character to max value
		bhi		INPUT		;if higher than, go back to input to try again
		cmp		#$90,D4		;check for error value
		beq		INPUT		;if error value, go back to input again

INPUT2	lea 	N2_PRMT,A1 	;points to start of message
		bsr.w 	out_string 	;prints the message
		bsr.w 	out_crlf 	;go to next line
		
		jsr		NMBR_2		;goes to our NMBR_2 label
		cmp		#9999,D7    ;comparing taken in character to max value
		bhi		INPUT2      ;if higher than, go back to input to try again
		cmp		#$90,D7		;check for error value
		beq		INPUT2		;check for error value
		rts                 ;if error value, go back to input again

;FROM HERE ON IS GIVEN CODE
		
******************************************************
*      
*      Subroutines...
*
******************************************************
*  Fetch a string until CR or LF and return it in
*   NOTE: a null termination is added
*   the buffer is provided by A1
* ** Stay in this until at least _1_ character is entered!
* ** This prevents problems with extra CR/LF/Null characters
******************************************************

in_string
        	move.l	D1,-(A7)
        	move.l	D2,-(A7)
        	move.l	A1,-(A7)
		move.l	#0, D2		; in D2 keep a count of how many characters we have
in_string_loop	jsr in_char
		tst.l	D1
		beq	in_string_loop	; ignore null characters if we get them
        	cmp.l	#CR,D1
        	beq.w	exit_in_string
        	cmp.l	#LF,D1		; Note LF gets caught on CF-server when prog run!
        	beq.w	exit_in_string
        	move.b	D1,(A1)+
		add.l	#1, D2
        	bra	in_string_loop
exit_in_string	tst.l	D2
		beq	in_string_loop	; loop back if we have 0 characters
		move.b #0,(A1)

        	move.l	(A7)+,A1
        	move.l	(A7)+,D2
        	move.l	(A7)+,D1
        	rts

******************************************************
* print CR, LF
******************************************************

out_crlf
        	move.l  D1,-(A7)

        	move	#CR,D1
        	jsr	out_char
        	move	#LF,D1
        	jsr	out_char

        	move.l	(A7)+,D1
        	rts

******************************************************
* Put out a string to the terminal
*  A1 points to start of string; 0 marks end of string
******************************************************

out_string
		move.l	D1,-(A7)
		move.l	A1,-(A7)
out_next_char
        	move.b	(A1)+,D1
        	jsr	out_char
        	tst.b	D1
        	bne	out_next_char
        	move.l	(A7)+,A1
        	move.l	(A7)+,D1
        	rts

******************************************************
*  D1 is printed to terminal
******************************************************

out_char
	        move.l  D0,-(A7)
        	move.l  #$0013,d0        ;Select function
        	TRAP    #15
        	move.l  (A7)+,D0
        	rts

******************************************************
* D1 is returned from the terminal
******************************************************

in_char 	move.l  D0,-(A7)

        	move.l	#$0010,d0
        	TRAP    #15
        	and.l	#$7F,d1		; strip off the parity bit
        	bsr	out_char 	; Echo the character back to the user

        	move.l  (A7)+,D0
        	rts

******************************************************
*     
*  End of Subroutines
*
******************************************************