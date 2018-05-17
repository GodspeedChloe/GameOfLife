#
# FILE:		$File$
# Author:	Chloe Jackson
#
# Description:	This file contains the main function for the game
#		as well as all the code necessary to run a simulation
#

#---------------------------------

#
# Numeric Constants
#

MAX_SIZE = 900			# 30^2 bytes in a board

#
# syscall constants
#

PRINT_STRING = 4
PRINT_CHAR = 11
PRINT_INT = 1
READ_INT = 5

#---------------------------------
# 
# DATA AREAS
#
	
	.data

	.align	2		# Word data must be on word boundaries
board_u:
	.space	MAX_SIZE
board_v:
	.space	MAX_SIZE
size:
	.word	0		# Actual number of values in the array
	
	.align	0		# String data doesn't have to be aligned
generations:			# Total number of generations we're doing
	.word	0
	
	.align	0
current_gen:			# Starts at 0, goes up to generations
	.word	0

	.align	0
startsize_a:			# Holds the value for # of generation 0 A cells
	.word	0
	
	.align	0

#
# Char's for the board and strings for UI
#

letter_A:
	.asciiz "A"
dash:
	.asciiz "-"
plus:
	.asciiz	"+"
space:
	.asciiz " "
pipe:	
	.asciiz "|"
newline:	
	.asciiz "\n"
banner_edge:
	.asciiz "**********************\n"
banner_mid:
	.asciiz "****  GameOfLife  ****\n"
gen_banner_left:
	.asciiz "\n====    GENERATION "
gen_banner_right:
	.asciiz "    ====\n"

#
# I/O Prompts and Warnings/Errors
#

prompt1:
	.asciiz "\nEnter board size: "
prompt2:
	.asciiz "\nEnter number of generations to run: "
prompt3:
	.asciiz "\nEnter number of live cells: "
prompt4:
	.asciiz "\nStart entering locations\n"
warning1:
	.asciiz	"\nWARNING: illegal board size, try again: "
warning2:
	.asciiz "\nWARNING: illegal number of generations, try again: "
warning3:
	.asciiz "\nWARNING: illegal number of live cells, try again: "
warning4:
	.asciiz "\nERROR: illegal point location\n"	

#
# CODE AREAS
#

	.text
	.align	2

	.globl	main

#
# Name:		main
# Description:	runs the colony game
#
# Arguments:	none
# Returns:	none
# Destroys:	
#

FRAMESIZE = 8
MAINFRAME = 20
main:
	addi	$sp, $sp,-MAINFRAME
	sw	$ra, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	li	$v0, PRINT_STRING	# Print banner top
	la	$a0, newline
	syscall

	la	$a0, banner_edge
	syscall

	la	$a0, banner_mid		# Print the Colony title
	syscall

	la	$a0, banner_edge	# Print the banner bottom
	syscall

	la	$a0, board_u		# Passing in board_u
	la	$a1, space
	jal	clear_board		# Fill board_u with spaces

	la	$a0, board_v		# Fill board_v with spaces
	la	$a1, space
	jal	clear_board

	jal	read_size		# Prompt and set size

	jal	read_generations	# Prompt and set generations

	la	$s1, generations	# Increment generations by 1
	lw	$s0, 0($s1)
	addi	$s0, $s0, 1
	sw	$s0, 0($s1)

	jal	read_start_A		# Prompt and set startsize_a	

	li	$v0, PRINT_STRING	# Print a "Start entering values"
	la	$a0, prompt4
	syscall

	li	$v1, 1			# Set to 1 for error checking
	la	$a0, board_u		# Read points into our board
	la	$a1, size
	la	$a2, startsize_a
	la	$a3, letter_A
	jal	read_points

	beq	$v1, $zero, done	# Exit if Error reading in points

	move	$s0, $zero		# Set current_gen to 0
	la	$s1, current_gen
	lw	$s0, 0($s1)
	move	$s2, $zero		# We start with 0, so u then v

main_loop:
	la	$s3, current_gen	# Retrieve current_gen
	lw	$s0, 0($s3)
	la	$s1, generations
	lw	$s1, 0($s1)
	beq	$s0, $s1, done		# Exit if gone past generations
	
	jal	print_gen_info		# Print generation banner
	la	$a1, size
	beq	$s2, $zero, load_board_u	# Read board_u if s2 == 0
	la	$a0, board_v			# Read board_v if s2 != 0
	la	$a1, size
	jal	print_board		# Print contents of board
	la	$a0, board_v
	la	$a1, board_u
	move	$s2, $zero		# Reset s2 to 0
	jal	do_rules

load_board_u:
	la	$a0, board_u
	la	$a1, size
	jal	print_board
	la	$a0, board_u
	la	$a1, board_v
	addi	$s2, $s2, 1		# Increment s2 if 0 s.t. s2 != 0

do_rules:
	jal	apply_rules		# Set up board for next generation
	addi	$s0, $s0, 1
	sw	$s0, 0($s3)		# Increment current_gen
	j	main_loop	
done:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, MAINFRAME
	jr	$ra


#
# Name:		read_start_A
# Description:	read in values until a valid colony A start size is entered
#
# Arguments:	none
# Returns:	none
# Destroys:	none
#

read_start_A:
        addi    $sp, $sp, -MAINFRAME
        sw      $ra, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        la      $a0, prompt3    # Prompt and read generations
        la      $a1, startsize_a
        jal     readnumber
        la	$s3, size
	lw	$s3, 0($s3)
	mult	$s3, $s3
	mflo	$s2		# s2 = size * size

read_st_A_loop:
        la      $s0, startsize_a
        lw      $s0, 0($s0)
        slti    $s1, $s0, 0     # if value is too small
        bne     $s1, $zero, read_st_A_again
        slt     $s1, $s2, $s0   # if value is too big
        bne     $s1, $zero, read_st_A_again
        j       read_start_A_done

read_st_A_again:
        la      $a0, warning3
        la      $a1, startsize_a
        jal     readnumber
        j       read_st_A_loop

read_start_A_done:
        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        lw      $s2, 8($sp)
        lw      $s3, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, MAINFRAME
        jr      $ra

#
# Name:		read_generations
# Description:	read in values until a valid generation total is entered
#
# Arguments:	none
# Returns:	none
# Destroys:	none
#

read_generations:
	addi    $sp, $sp, -MAINFRAME
        sw      $ra, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

	la	$a0, prompt2	# Prompt and read generations
	la	$a1, generations
	jal	readnumber
	li	$s2, 20

read_gens_loop:
	la	$s0, generations
	lw	$s0, 0($s0)
	slti	$s1, $s0, 0	# if value is too small
	bne	$s1, $zero, read_gens_again
	slt	$s1, $s2, $s0	# if value is too big
	bne	$s1, $zero, read_gens_again
	j	read_generations_done

read_gens_again:
	la	$a0, warning2
	la	$a1, generations
	jal	readnumber
	j	read_gens_loop

read_generations_done:
        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        lw      $s2, 8($sp)
        lw      $s3, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, MAINFRAME
        jr      $ra

#
# Name:		read_size
# Description:	reads in values until a valid size is entered
#
# Arguments:	none
# Returns:	none
# Destroys:	none
#

read_size:
	addi	$sp, $sp, -MAINFRAME
	sw	$ra, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	
        la      $a0, prompt1    # Prompt and read size
        la      $a1, size
        jal     readnumber
	li	$s2, 30

read_size_loop:
	la	$s0, size
	lw	$s0, 0($s0)
	slti	$s1, $s0, 4	# if value is too small
	bne	$s1, $zero, read_size_again
	slt	$s1, $s2, $s0	# if value is too big
	bne	$s1, $zero, read_size_again
	j	read_size_done

read_size_again:
	la	$a0, warning1
	la	$a1, size
	jal	readnumber
	j	read_size_loop

read_size_done:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, MAINFRAME
	jr	$ra

#
# Name:		readnumber
# Description:	reads in a number for the parameters 
#
# Arguments:	a0 is the prompt
#		a1 is value to be set
#
# Returns:	none
# Destroys:	none
#

readnumber:
	addi	$sp, $sp, -FRAMESIZE
	sw	$ra, 4($sp)
	sw	$s0, 0($sp)	

	move	$s0, $a1		# s0 is address of size of board

	li	$v0, PRINT_STRING	# Print a "Enter board size: "
	syscall

	li	$v0, READ_INT		# we're reading in
	syscall

	sw	$v0, 0($s0)

	lw	$s0, 0($sp)
	lw	$ra, 4($sp)
	addi	$sp, $sp, FRAMESIZE

	jr	$ra
	
#
# Name:		read_points
# Description:	reads in row, col points into a board
#
# Arguments:	a0 is the address of the board
#		a1 is the size of the board
#		a2 is the number of points for the board
#		a3 is char of cell type A or B
# 
# Returns:	v1 is 0 if input error
# Destroys:	t0, t1, t2, t3, t4, t5, t6
#

read_points:
	addi    $sp, $sp, -FRAMESIZE
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)

	li	$t6, 1		# No error yet, return 1
	li	$t5, 30		# For use in calculating location
	lw	$s0, 0($a1)	# s0 = size of board
	addi	$s0, $s0, -1	# Decrement for bounds logic
	li	$t0, 0		# Our loop counter
	lw	$t1, 0($a2)	# t1 <- number of insertions

points_loop:
	beq	$t0, $t1, points_done
	addi	$t0, $t0, 1	# Increment loop counter
	
	li	$v0, READ_INT	# Get our row coordinate
	syscall
	move	$t3, $v0	
	slti	$a1, $t3, 0	# If input is too small
	bne	$a1, $zero, points_error
	slt	$a1, $s0, $t3	# If input is too big
	bne	$a1, $zero, points_error
	
	li	$v0, READ_INT	# Get our column coordinate
	syscall
	move	$t2, $v0
	slti    $a1, $t2, 0     # If input is too small
        bne     $a1, $zero, points_error
        slt     $a1, $s0, $t2   # If input is too big
        bne     $a1, $zero, points_error

	mult	$t3, $t5
	mflo	$t3		# t3 = t3 * 30
	
	add	$t4, $t2, $t3	# t4 = t2 + t3 (this is the offset into board)
	add	$t4, $t4, $a0	# t4: offset into board
	la	$a1, space	# a1 is ascii space
	lb	$a1, 0($a1)
	lb	$t2, 0($t4)	# t2 is cell at row, col in board
	bne	$t2, $a1, points_error	# Error if cell is occupied
	lb	$t3, 0($a3)	# t3 = "A" or "B"
	sb	$t3, 0($t4)	# Store letter into board
	j	points_loop	# Go again

points_error:
	li	$v0, PRINT_STRING	
	la	$a0, warning4	# Print error
	syscall
	move	$t6, $zero	# We have an error, return 0

points_done:
	move	$v1, $t6
	lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, FRAMESIZE

        jr      $ra

#
# Name:		clear_board
# Description:	takes a board and clears it
#
# Arguments:	a0 is the address of the board
#		a1 is the address of an ascii space
#
# Returns:	none
# Destroys:	t0, t1, t2, t3
#

clear_board:
	addi    $sp, $sp, -FRAMESIZE
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
	
	move	$s0, $a0	# s0 = pointer to start of board
	lb	$t1, 0($a1)	# t1 = an ascii space " "
	li	$t3, MAX_SIZE	

clear_loop:
	beq	$t3, $zero, clear_done
	addi	$t3, $t3, -1
	add	$t2, $t3, $s0	# offset into board
	sb	$t1, 0($t2)	# Board[t1] = " "
	j	clear_loop

clear_done:
	lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, FRAMESIZE

        jr      $ra

#
# Name:		print_board
# Description:	prints the contents of a board
#
# Arguments:	a0 is the address of the board
#		a1 is the size of the board
#
# Returns:	none
# Destroys:	t0, t1, t2, t3, t4, t5
#

print_board:
	addi    $sp, $sp, -FRAMESIZE
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
	
	move	$s0, $a0	# s0 = pointer to start of board
	move	$t0, $zero	# initialize loop counter
	move	$t2, $a1	# t2 = width of a row
	lw	$t2, 0($t2)
	addi	$t1, $t2, 2	# total width of line to print 
	li	$v0, PRINT_STRING	
	li	$t5, 30		# for use in printing the board
	la	$a0, plus
	syscall
	la	$a0, dash

print_top_loop:
	beq	$t0, $t2, reset_count
	addi	$t0, $t0, 1	# increment loop counter
	syscall
	j	print_top_loop

reset_count:
	la	$a0, plus
	syscall
	la	$a0, newline
	syscall
	move	$t0, $zero	# set loop counter to 0

print_body_loop:
	li	$v0, PRINT_STRING
	beq	$t0, $t2, print_bottom
	la	$a0, pipe
	syscall
	move	$t3, $zero	# reset inner loop counter

print_row_loop:
	li	$v0, PRINT_CHAR
	beq	$t3, $t2, add_border_end
	mult	$t0, $t5
	mflo	$t4		# t4 = t0 * 30
	add	$t4, $t4, $t3	# t4 = t4 + t3 // gives us our board index
	add	$t4, $t4, $s0	# t4 = t4 + s0 // this is the address of byte
	lb	$a0, 0($t4)	# a0 = byte to print
	syscall
	
	addi	$t3, $t3, 1
	j	print_row_loop

add_border_end:
	li	$v0, PRINT_STRING
	la	$a0, pipe	# print a pipe
	syscall
	la	$a0, newline	# print a newline char
	syscall

	addi	$t0, $t0, 1	
	j	print_body_loop

print_bottom:
	move	$t0, $zero	# reset loop counter
	la	$a0, plus
	syscall

print_bottom_loop:
	beq	$t0, $t2, print_done
	addi	$t0, $t0, 1	# increment loop counter
	la	$a0, dash	# print a dash
	syscall
	
	j	print_bottom_loop

print_done:
	la	$a0, plus	# print a plus
	syscall
	la	$a0, newline	# print a newline char
	syscall

	lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, FRAMESIZE

        jr      $ra

#
# Name:	print_gen_info
# Description:	Prints the banner for the specific generation being shown
#
# Arguments:	none
# Returns:	none
# Destroys:	none
#

print_gen_info:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	li	$v0, PRINT_STRING	# print "\n====    GENERATIONS "
	la	$a0, gen_banner_left
	syscall
	li	$v0, PRINT_INT		# print which gen we're on
	la	$a0, current_gen
	lw	$a0, 0($a0)
	syscall
	li	$v0, PRINT_STRING	# print "    ====\n"
	la	$a0, gen_banner_right
	syscall

	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

#
# Name: count_neighbors
# Description: Counts the number n to decide what happens to a cell
# 
# Arguments:	a0 is the board
#		a1 is the row coordinate
#		a2 is the col coordinate
#
# Returns:	v0 is the number n
# Destroys:	none
#

count_neighbors:
	addi	$sp, $sp, -MAINFRAME
	sw	$ra, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	move	$s0, $a0	# s0 <- board_u|board_v
	li	$s3, 30		# s3 = 30. For use in indexing board
	move	$s1, $zero	# Initialize n to 0
	la	$a3, size
	lw	$a3, 0($a3)	# a3 <- size
	addi	$a3, $a3, -1	# account for 0 indexing

	mult	$s3, $a1
	mflo	$s2		# s2 = 30 * row
	add	$s2, $s2, $a2	# s2 = s2 + col
	add	$s2, $s2, $s0	# offset into board

	beq	$a2, $zero, left_side	# cell is in leftmost col	
	beq	$a2, $a3, right_side	# cell is in rightmost col
	beq	$a1, $zero, top_row	# cell in top row but not corner
	beq	$a1, $a3, bottom_row	# cell in bottom row but not corner	
	
#
# If not an edge case, count without wrapping
#

	addi	$s2, $s2, -31	# s2 = s2 - 1 (s2 is now top left)
	lb	$a0, 0($s2)	# a0 = byte in the top left 
	jal	cell_type
	add	$s1, $s1, $v0	# s1 = s1 + (-1|0|1) 
	addi	$s2, $s2, 1	# s2 is now direct above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now top right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now directly right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -2	# s2 is now direct left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now bottom left from cell	
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now direct below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now bottom right to cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0	
	j	count_done

#
# If col == 0, do left_side wrapping to right border
#

left_side:			
	beq	$a1, $zero, left_top	# cell in top left corner
	beq	$a1, $a3, left_bottom	# cell in bottom left corner
	addi	$s2, $s2, -30	# s2 is now directly above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now top right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now directly right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now bottom right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now directly below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	add	$s2, $s2, $a3	# s2 is now against the right border
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# going up right border
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If col == size - 1, do right_side wrapping to left border
#

right_side:
	beq	$a1, $zero, right_top	# cell in top right corner
	beq	$a1, $a3, right_bottom	# cell in bottom right corner
	addi	$s2, $s2, -30	# s2 is now directly above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now top left from the cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now directly left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now bottom left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now directly below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	sub	$s2, $s2, $a3	# s2 is now against the left border
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# going up left border
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == 0, do top_row wrapping to bottom border
#

top_row:
	mult	$s3, $a3
	mflo	$a3		# 30 * (size - 1) allows jump to bottom edge
	add	$s2, $s2, -1	# s2 is now directly left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now bottom left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	#s2 is now directly below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now bottom right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is now directly right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	add	$s2, $s2, $a3	# s2 is now bottom row, right
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now bottom row, direct below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now bottom row, left
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == size - 1, do bottom_row wrapping to top border
#

bottom_row:
	mult	$s3, $a3
	mflo	$a3		# 30 * (size - 1) allows jump to top edge
	addi	$s2, $s2, -1	# s2 is now directly left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is now top left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now directly above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now top right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now directly right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	sub	$s2, $s2, $a3	# s2 is now top row, right
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now top row, direct above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now top row, left
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == 0 and col == 0, do left_top with wrapping to other corners etc
#

left_top:
	mult	$s3, $a3
	mflo	$s3		# 30 * (size - 1) allows vertical jump
	addi	$s2, $s2, 1	# s2 is now directly right from cell
	lb	$a0, 0($s2)	
	jal	cell_type
	add	$s1, $s1, $v0	
	addi	$s2, $s2, 30	# s2 is now bottom right from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now directly below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is location of cell
	add	$s2, $s2, $a3	# s2 is right top corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is one below right top corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30
	add	$s2, $s2, $s3	# s2 is now bottom right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	sub	$s2, $s2, $a3	# s2 is now bottom left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now one right of bottom left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == size - 1 and col == 0, do left_bottom with wrapping 
#

left_bottom:
        mult    $s3, $a3
        mflo    $s3             # 30 * (size - 1) allows vertical jump
	addi	$s2, $s2, 1	# s2 is now directly to right of cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is now top right from cell
        lb      $a0, 0($s2)
        jal     cell_type
        add     $s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is now directly above cell
        lb      $a0, 0($s2)
        jal     cell_type
        add     $s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is location of cell
	sub	$s2, $s2, $s3	# s2 is now top left corner
	lb	$a0, 0($s2)	
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now one right of top left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1
	add	$s2, $s2, $a3	# s2 is now top right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	add	$s2, $s2, $s3	# s2 is now bottom right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is now one above bottom right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == 0 and col == size - 1, do right_top with wrapping
#

right_top:
        mult    $s3, $a3
        mflo    $s3             # 30 * (size - 1) allows vertical jump
	addi	$s2, $s2, -1	# s2 is now directly left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is now bottom left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now directly below cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is location of the cell
	add	$s2, $s2, $s3	# s2 is now bottom right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is one left from bottom right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1
	sub	$s2, $s2, $a3	# s2 is now bottom left right
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	sub	$s2, $s2, $s3	# s2 is now top left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is one below top left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

#
# If row == size - 1 and col == size - 1, do right_bottom with wrapping
#

right_bottom:
        mult    $s3, $a3
        mflo    $s3             # 30 * (size - 1) allows vertical jump
	addi	$s2, $s2, -1	# s2 is now directly left from cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0	
	add	$s2, $s2, -30	# s2 is now top left from cell
	lb	$a0, 0($s2)
	jal	cell_type	
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1	# s2 is now directly above cell
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 30	# s2 is location of the cell
	sub	$s2, $s2, $s3	# s2 is now top right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -1	# s2 is one left from top right corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, 1
	sub	$s2, $s2, $a3	# s2 is now top left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	add	$s2, $s2, $s3	# s2 is now bottom left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	addi	$s2, $s2, -30	# s2 is one above bottom left corner
	lb	$a0, 0($s2)
	jal	cell_type
	add	$s1, $s1, $v0
	j	count_done

count_done:
	move	$v0, $s1	# v0 = count
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, MAINFRAME
	jr	$ra

#
# Name:	cell_type
# Description: Tells whether a cell is alive or not
#
# Arguments:	a0 is a byte
# Returns:	v0 is 1 if a0 is "A", 0 if neither
# Destroys:	none
#

cell_type:
	addi	$sp, $sp, -FRAMESIZE
	sw	$ra, 4($sp)
	sw	$s0, 0($sp)
	li	$v0, 1		# v0 is A
	la	$s0, letter_A
	lb	$s0, 0($s0)	# s0 = "A"
	beq	$a0, $s0, cell_type_done	# if a0 == "A"
	move	$v0, $zero	# return 0 if not A
 
cell_type_done:
	lw	$s0, 0($sp)
	lw	$ra, 4($sp)
	addi	$sp, $sp, FRAMESIZE
	jr	$ra

#
# Name:	apply_rules
# Description:	Meat and potatoes.  Applies the rules to boards U and V
#
# Arguments:	a0 is the board to read from
#		a1 is the board to write to
#
# Returns:	none
# Destroys:	t0, t1, t2, t3, t4, t5
#

apply_rules:
	addi    $sp, $sp, -FRAMESIZE
        addi	$sp, $sp, -FRAMESIZE
	sw      $ra, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
        sw      $s0, 0($sp)

	move	$s0, $a0	# s0 <-- board_u|v
	move	$s1, $a1	# s1 <-- board_v|u
	move	$t0, $zero	# set our loop counter and row value
	la	$s2, size
	lw	$s2, 0($s2)	# s2 is size of board

apply_outer_loop:
	beq	$t0, $s2, apply_done
	move	$t1, $zero	# set our loop counter and column value
	
apply_inner_loop:
	beq	$t1, $s2, apply_inner_done
	move	$a0, $s0	# a0 <-- Board we're reading from
	move	$a1, $t0	# a1 <-- Row coordinate
	move	$a2, $t1	# a2 <-- Col coordinate
	jal	count_neighbors
	move	$t2, $v0	# t2 <-- neighbor value
	mult	$t5, $t0	
	mflo	$t3		# t3  = 30 * row
	add	$t3, $t3, $s0
	add	$t3, $t3, $t1	# t3 <-- row, col value
	lb	$t4, 0($t3)	# t4 is char in row, col
	sub	$t3, $t3, $s0
	add	$t3, $t3, $s1	# t3 <-- row, col in write board
	move	$a0, $t4
	jal	cell_type	# what cell_type is this cell?
	addi	$v0, $v0, -1
	beq	$v0, $zero, byte_A	# if alive
	j	byte_else		# else type 0
byte_A:
	slti	$t7, $t2, 2	# if n < 2, then perish
	bne	$t7, $zero, kill
	slti	$t7, $t2, 4	# if n < 4, then stay alive
	bne	$t7, $zero, stay_A
	j	kill
stay_A:
	sb	$t4, 0($t3)	# write an A in write board
	j	byte_done
kill:
	la      $a0, space
        lb      $a0, 0($a0)
        sb      $a0, 0($t3)     # write a dash in write board
        j       byte_done
byte_else:
	move	$a0, $zero
	addi	$a0, $a0, 3
	beq	$a0, $t2, birth_A
	j	kill
birth_A:
	la	$a0, letter_A
	lb	$a0, 0($a0)	# a0 <-- ascii A
	sb	$a0, 0($t3)	# write an A into write board
	j	byte_done
byte_done:
	addi	$t1, $t1, 1	# increment loop counter
	j	apply_inner_loop

apply_inner_done:
	addi	$t0, $t0, 1	# increment loop counter
	j	apply_outer_loop

apply_done:
	move	$a0, $s0
	la	$a1, space
	jal	clear_board	# clear the board we read from
	lw      $s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
        lw      $ra, 12($sp)
	addi	$sp, $sp, FRAMESIZE
        addi    $sp, $sp, FRAMESIZE
	jr	$ra
