/*
------------------------------------------------------------
Program: Recursive Fibonacci Sequence
Course: CST-307

Purpose:
    Calculate and print the first 10 Fibonacci numbers
    using a recursive ARM Assembly procedure.
Fibonacci definition:
    F(n) = 1                 if n < 2
    F(n) = F(n-1) + F(n-2)  otherwise

Maximum input: n = 9

Registers:
    r0 = Input parameter and return value
    r1 = Temporary register for UART
    r2 = UART address register
    r4 = Stores first recursive result / tens digit counter
    r5 = Saves original n / ones digit when printing
    r6 = Main loop counter
    sp = Stack pointer
    lr = Link register
    pc = Program counter
------------------------------------------------------------
*/

.global _start

_start:

    LDR sp, =0x3FFFFFFC    @ Initialize stack pointer

    MOV r6, #0             @ Start with n = 0

MAIN_LOOP:

    MOV r0, r6             @ Pass n into Fibonacci
    BL FIBONACCI           @ Call recursive procedure

    BL PRINT_NUMBER        @ Print result in r0

    ADD r6, r6, #1         @ Increase n by 1
    CMP r6, #10            @ Have we calculated F(9)?
    BLT MAIN_LOOP          @ Continue if n is less than 10

STOP:
    B STOP                 @ End program


@ ---------------------------------------------------------
@ RECURSIVE FIBONACCI PROCEDURE
@
@ Input:  r0 = n
@ Output: r0 = F(n)
@ ---------------------------------------------------------

FIBONACCI:

    CMP r0, #2             @ Check if n is less than 2
    BLT FIB_BASE           @ Base case: return 1

    PUSH {r4, r5, r6, lr}  @ Save registers and return address

    MOV r5, r0             @ Save original n in r5

    SUB r0, r5, #1         @ Calculate n - 1
    BL FIBONACCI           @ Calculate F(n - 1)

    MOV r4, r0             @ Save first result in r4

    SUB r0, r5, #2         @ Calculate n - 2
    BL FIBONACCI           @ Calculate F(n - 2)

    ADD r0, r4, r0         @ Add both results

    POP {r4, r5, r6, pc}   @ Restore registers and return


FIB_BASE:

    MOV r0, #1             @ F(0) = 1 and F(1) = 1
    BX lr                  @ Return to calling procedure


@ ---------------------------------------------------------
@ PRINT NUMBER PROCEDURE
@
@ Input: r0 = Fibonacci result (0 through 55)
@ Output: Displays the number using JTAG UART
@
@ JTAG UART base address: 0xFF201000
@ ---------------------------------------------------------

PRINT_NUMBER:

    PUSH {r0, r4, r5, lr}  @ Save original result and registers

    MOV r4, #0             @ Initialize tens counter

COUNT_TENS:

    CMP r0, #10            @ Check if number is at least 10
    BLT PRINT_DIGITS

    SUB r0, r0, #10        @ Subtract 10
    ADD r4, r4, #1         @ Increase tens counter
    B COUNT_TENS

PRINT_DIGITS:

    MOV r5, r0             @ Save ones digit (remainder) in r5

    CMP r4, #0             @ Check if tens digit exists
    BEQ PRINT_ONES

    ADD r0, r4, #48        @ Convert tens digit to ASCII
    BL PUT_CHAR            @ Print tens digit

PRINT_ONES:

    ADD r0, r5, #48        @ Convert ones digit to ASCII
    BL PUT_CHAR            @ Print ones digit

    MOV r0, #10            @ ASCII newline character
    BL PUT_CHAR            @ Move to next line

    POP {r0, r4, r5, pc}   @ Restore original result and return


@ ---------------------------------------------------------
@ PUT CHARACTER PROCEDURE
@
@ Input: r0 = ASCII character
@ Sends one character to JTAG UART.
@ ---------------------------------------------------------

PUT_CHAR:

    LDR r2, =0xFF201000    @ JTAG UART data register

WAIT_UART:

    LDR r1, [r2, #4]       @ Read UART control register
    LSR r1, r1, #16        @ Check available FIFO space
    CMP r1, #0
    BEQ WAIT_UART          @ Wait if FIFO is full

    STR r0, [r2]           @ Send character to UART
    BX lr                  @ Return