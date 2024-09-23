.equ timer_control, 0x72000
.equ timer_load, 0x72001
.equ timer_interrupt, 0x72003

.equ pcb_link, 0
.equ pcb_reg1, 1
.equ pcb_reg2, 2
.equ pcb_reg3, 3
.equ pcb_reg4, 4
.equ pcb_reg5, 5
.equ pcb_reg6, 6
.equ pcb_reg7, 7
.equ pcb_reg8, 8
.equ pcb_reg9, 9
.equ pcb_reg10, 10
.equ pcb_reg11, 11
.equ pcb_reg12, 12
.equ pcb_reg13, 13
.equ pcb_sp, 14
.equ pcb_ra, 15
.equ pcb_ear, 16
.equ pcb_cctrl, 17
.equ pcb_timeslice, 18
.equ pcb_enabled, 18
.global main
.text

main:
	addi $2, $0, 1
    sw $2, time_slice($0)

    addi $5, $0, 0x4d                   # Unmask IRQ2,KU=1,OKU=1,IE=0,OIE=1
    movgs $cctrl, $5 

    la $1, task1_pcb                    # Setup the pcb for task 1
    la $2, task2_pcb                    # Setup the link field
    sw $2, pcb_link($1)                     
    la $2, task1_stack                  # Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, serial_main                   # Setup the $ear field
    sw $2, pcb_ear($1)    
    la $2, exit                         # Set return address to go to exit subroutine
    sw $2, pcb_ra($1)
    sw $5, pcb_cctrl($1)                # Setup the $cctrl field
    addi $2, $0, 1                      # Give task 1 a time slice of 1
    sw $2, pcb_timeslice($1)
    addi $2, $0, 1                      # Enable a task
    sw $2, pcb_enabled($1)

    la $1, task2_pcb                    # Setup the pcb for task 1
    la $2, task3_pcb                    # Setup the link field
    sw $2, pcb_link($1)                     
    la $2, task2_stack                  # Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, parallel_main                   # Setup the $ear field
    sw $2, pcb_ear($1)
    la $2, exit                         # Set return address to go to exit subroutine
    sw $2, pcb_ra($1)
    sw $5, pcb_cctrl($1)                # Setup the $cctrl field
    addi $2, $0, 1                      # Give task 2 a time slice of 1
    sw $2, pcb_timeslice($1)
    addi $2, $0, 1                      # Enable a task
    sw $2, pcb_enabled($1)

    la $1, task3_pcb                    # Setup the pcb for task 1
    la $2, task1_pcb                    # Setup the link field
    sw $2, pcb_link($1)                     
    la $2, task3_stack                  # Setup the stack pointer
    sw $2, pcb_sp($1)
    la $2, rocks_main                   # Setup the $ear field
    sw $2, pcb_ear($1)
    la $2, exit                         # Set return address to go to exit subroutine
    sw $2, pcb_ra($1)
    sw $5, pcb_cctrl($1)                # Setup the $cctrl field
    addi $2, $0, 4                      # Give task 3 a time slice of 4
    sw $2, pcb_timeslice($1)
    addi $2, $0, 1                      # Enable a task
    sw $2, pcb_enabled($1)

    sw $0, timer_interrupt($0)          # Ensures no old interrupts

	addi $2, $0, 0x3                   # Enable the timer autorestart 
	sw $2, timer_control($0)

	addi $2, $0, 0x18                  # Put autoload value of 100 interrupts per second (1/100 * 2400Hz)
	sw $2, timer_load($0)

	movsg $2, $evec                     # Copy the old handlers's Address into $2
	sw $2, old_vector($0)               # Save it to memory
	la $2, handler                  	# Get the address of our handler
	movgs $evec, $2                     # Copy it into $evec register

    la $1, task1_pcb                    # Set first task as the current task
    sw $1, current_task($0)

    j load_context

handler:
	movsg $13, $estat               	# Get the value of exception status registr
	andi $13, $13, 0xffB0               # Check if interrupt is anything other than irq2, we don't handle ourselves
	beqz $13, handle_timer              # If it is one of ours, go to our handler

	lw $13, old_vector($0)              # Otherwise jump to default handler that we saved earlier
	jr $13
	
handle_timer:

	sw $0, timer_interrupt($0)          # Acknowledge irq2 interrupt
    
	lw $13, counter($0)                 # Load counter value in $13
	addi $13, $13, 1                    # Store the contents of $13 into the memory location ‘counter’
	sw $13, counter($0)

    lw $13, time_slice($0)              # Load time slice value in $13
	subi $13, $13, 1
    sw $13, time_slice($0)

    beqz $13, dispatcher
	
	rfe                                 # Return from Exception

dispatcher:
save_context:
    lw $13, current_task($0)            # Get the base address of the current PCB

    sw $1, pcb_reg1($13)                # Save the registers
    sw $2, pcb_reg2($13)
    sw $3, pcb_reg3($13)
    sw $4, pcb_reg4($13)
    sw $5, pcb_reg5($13)
    sw $6, pcb_reg6($13)
    sw $7, pcb_reg7($13)
    sw $8, pcb_reg8($13)
    sw $9, pcb_reg9($13)
    sw $10, pcb_reg10($13)
    sw $11, pcb_reg11($13)
    sw $12, pcb_reg12($13)
    sw $sp, pcb_sp($13)
    sw $ra, pcb_ra($13)

    movsg $1, $ers                      # $1 is saved now so we can use it, so Get the old value of $13
    sw $1, pcb_reg13($13)               # Save it to the pcb

    movsg $1, $ear                      # Save $ear
    sw $1, pcb_ear($13)

    movsg $1, $cctrl                    # Save $cctrl
    sw $1, pcb_cctrl($13)

schedule:
    lw $13, current_task($0)            # Get current task
    lw $13, pcb_link($13)               # Get next task from pcb_link field
    sw $13, current_task($0)            # Set next task as current task

load_context:
    lw $13, current_task($0)            # Get PCB of current task

    lw $1, pcb_enabled($13)             # If task is not enabled, move on to the next task
    beqz $1, schedule

    lw $1, pcb_reg13($13)               # Get the PCB value for $13 back into $ers
    movgs $ers, $1

    lw $1, pcb_ear($13)                 # Restore $ear
    movgs $ear, $1

    lw $1, pcb_cctrl($13)               # Restore $cctrl
    movgs $cctrl, $1

    lw $1, pcb_timeslice($13)
    sw $1, time_slice($0)

    lw $1, pcb_reg1($13)                # Restore the other registers
    lw $2, pcb_reg2($13)
    lw $3, pcb_reg3($13)
    lw $4, pcb_reg4($13)
    lw $5, pcb_reg5($13)
    lw $6, pcb_reg6($13)
    lw $7, pcb_reg7($13)
    lw $8, pcb_reg8($13)
    lw $9, pcb_reg9($13)
    lw $10, pcb_reg10($13)
    lw $11, pcb_reg11($13)
    lw $12, pcb_reg12($13)
    lw $sp, pcb_sp($13)
    lw $ra, pcb_ra($13)

    rfe                                 # Return to the new task

exit:
    lw $13, current_task($0)            # Disable the task that called exit
    sw $0, pcb_enabled($13)
    j schedule

.bss
old_vector:                             # Store old default handler address here
    .word 

time_slice:
    .word
    
current_task:
    .word

    .space 19
task1_pcb:

    .space 19
task2_pcb:

   .space 19
task3_pcb:

    .space 200
task1_stack:

    .space 200
task2_stack:

    .space 200
task3_stack:

