.equ timer_control, 0x72000
.equ timer_load, 0x72001
.equ timer_interrupt, 0x72003

.global main
.text

main:
	sw $ra, ra($0)                      # Save original return address	

	movsg $2, $cctrl                    # Copy current value of $cctrl into $2
	andi $2, $2, 0x000f                 # Mask all interupts
	ori $2, $2, 0x42                    # Enable IRQ2 and IE (global interrupt enable)
	movgs $cctrl, $2                    # Copy the new CPU control value back to $cctrl
	
	movsg $2, $evec                     # Copy the old handlers's Address into $2
	sw $2, old_vector($0)               # Save it to memory
	la $2, handler                  	# Get the address of our handler
	movgs $evec, $2                     # Copy it into $evec register

    sw $0, timer_interrupt($0)          # Ensures no old interrupts

	addi $13, $0, 0x3                   # Enable the timer autorestart 
	sw $13, timer_control($0)

	addi $13, $0, 0x18                  # Put autoload value of 100 interrupts per second (1/100 * 2400Hz)
	sw $13, timer_load($0)

    jal serial_main
    lw $ra, ra($0)
    jr $ra

handler:
	movsg $13, $estat               	# Get the value of exception status registr
	andi $13, $13, 0xffB0               # Check if interrupt is anything other than irq2, we don't handle ourselves
	beqz $13, handle_timer              # If it is one of ours, go to our handler

	lw $13, old_vector($0)              # Otherwise jump to default handler that we saved earlier
	jr $13
	
handle_timer:
	sw $0, timer_interrupt($0)                  # Acknowledge irq2 interrupt
	
	lw $13, counter($0)                 # Load counter value in $13
	
	addi $13, $13, 1                    # Store the contents of $13 into the memory location ‘counter’
	sw $13, counter($0)
	
	rfe                                 # Return from Exception

.bss
old_vector:                             # Store old default handler address here
    .word 
ra: 
    .word
