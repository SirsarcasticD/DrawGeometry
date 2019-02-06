##
##  DONOVAN CHIAZZESE, 260742780
##

.data  # start data segment with bitmapDisplay so that it is at 0x10010000
.globl bitmapDisplay # force it to show at the top of the symbol table
bitmapDisplay:    .space 0x80000  # Reserve space for memory mapped bitmap display
bitmapBuffer:     .space 0x80000  # Reserve space for an "offscreen" buffer
width:            .word 512       # Screen Width in Pixels, 512 = 0x200
height:           .word 256       # Screen Height in Pixels, 256 = 0x100

lineDataFileName: .asciiz "teapotLineData.bin"
errorMessage:     .asciiz "Error: File must be in directory where MARS is started."

.text
##################################################################
# main entry point

main:	#la $a0 lineDataFileName
	#la $a1 lineData
	#la $a2 lineCount
	#jal loadLineData
	#la $s0 lineData 	# keep buffer pointer handy for later
	#la $s1 lineCount
	#lw $s1 0($s1)	   	# keep line count handy for later
	
	
	li $t0 -1
	
	
	li $a0 0		# Choose starting x point
	li $a1 0		# Choose startin y point
	li $a2 511		# Choose end x point
	li $a3 255		# Choose end y point
	
	jal drawLine		# DrawLine from point (x1,y1) to point (x2,y2) onto buffer
        jal copyBuffer		# Copy buffer onto bitmapDisplay
        jal clearBuffer		# Clear buffer
       
        li $a0 200		# Choose starting x point
	li $a1 33		# Choose startin y point
	li $a2 51		# Choose end x point
	li $a3 100		# Choose end y point
	
	jal drawLine		# Call drawLine function

        jal copyBuffer		# Call copyBuffer function
        jal clearBuffer
        
        li $v0, 10     		# load exit call code 10 into $v0
	syscall         	# call operating system to exit
        
        
        
        

###############################################################
# void clearBuffer( int colour )
clearBuffer:

	la $t1 0x10090000	# Adress of the Beginning of bitmap Display memory
	li $t2 0x00000000
	la $t3 0x10180000
loop:   
        sw $t2 ($t1)
        addi $t1 $t1 4
        ble $t1 $t3 loop
        
        
	jr $ra

###############################################################
# copyBuffer()
copyBuffer:
	
	li $t4 0x10010000		# Adress of beginning of bitmap Display
	li $t5 0x10090000		# Adress of end of bitmap Display

loop2:	lw $t6 ($t5)
	sw $t6 ($t4)
	addi $t4 $t4 4
	addi $t5 $t5 4
	
	
        la $t3 0x10180000
        ble $t5 $t3 loop2

		jr $ra

###############################################################
# drawPoint( int x, int y ) 
drawPoint: 
	
		#la $t0 ($a0)			
		#la $t1 ($a1)			
		lw $t0 0($sp)			# get value of x from stack
		lw $t1 4($sp)			# get value of y from stack
		
		bge $t0 511 x_is_invalid	# if x > 511 branch to end of functuion 
		ble $t0 0 x_is_invalid		# if x < 0 branch to end of functuion
		bge $t1 255 y_is_invalid	# if y > 255 branch to end of functuion
		ble $t1 0 y_is_invalid		# if y < 0 branch to end of functuion
						
		la $t7 0x10090000		#beginning of buffer
		
		li $t2 4
		mult $t0 $t2
		mflo $t0			# x after offset
		
		li $t2 2048
		mult $t1 $t2
		mflo $t1			# y after offset
		
		add $t2 $t0 $t1			# add x and y
		add $t2 $t2 $t7			# Value of X and Y coordinate (add to address)
		
		li $t8 0x00ffffff		# Value of green
		
		sw $t8 ($t2)			#change color to green at X,Y coordinate
		
		
y_is_invalid:
x_is_invalid:
endoffunc:	
		jr $ra

###############################################################
# void drawline( int x0, int y0, int x1, int y1 )
drawLine:

		addi $sp $sp -40
		
		sw $ra 32($sp)
		
		li $t0 1		
		sw $t0 16($sp)		# offsetX = 1
		
		li $t0 1		
		sw $t0 20($sp)		# offsetY = 1
		
		sw $a0 0($sp)		# x0 also x
		lw $s0 0($sp)		# x0 into save register
		
		sw $a1 4($sp)		# y0 also y
		lw $s1 4($sp)		# y0 into save register
		
		sw $a2 8($sp)		# x1
		lw $s2 8($sp)		# x1 into save register
		
		sw $a3 12($sp)		# y1
		lw $s3 12($sp)		# y1 into save register
		
		sub $t0 $s2 $s0		# dX = x1 - x0
		sw $t0 24($sp)		# set dX
		
		sub $t0 $s3 $s1		# dy = y1 - y0
		sw $t0 28($sp)		# set dY
		
					# Finish setting variables
		
		lw $t0 24($sp)		# get dX
		bgt $t0 -1 endofif1	# if (dX < 0) do		
		sub $t0 $0 $t0		# 0 - dX = - dX
		sw $t0 24($sp)		# set dX = -dX
		
		li $t0 -1
		sw $t0 16($sp)		# set offsetX = -1
		
endofif1:	

		lw $t0 28($sp)		# get dY
		bgt $t0 -1 endofif2	# if (dY < 0) do		
		sub $t0 $0 $t0		# 0 - dY = -dY
		sw $t0 28($sp)		# set dy = -dY
		
		li $t0 -1		
		sw $t0 20($sp)		# offsetY = -1
		
endofif2:			
				
		jal drawPoint
		
		
		lw $t0 24($sp)		# get dX
		lw $t1 28($sp)		# get dY
		beq $t0 $t1 else	# if (dX = dY) do
		blt $t0 $t1 else	# if (dX > dY) do
		
		
		lw $t0 24($sp)		# get dX
		sw $t0 40($sp)		# error = dX
		
while:		beq $s0 $s2 end		# while x0 != x1 do

		lw $t0 28($sp)		# get dY
		add $t0 $t0 $t0		# 2dY
		
		lw $t1 40($sp)		# get error
		sub $t1 $t1 $t0		# error = error - 2dY
		sw $t1 40($sp)		# set error
		
		bgt $t1 -1 endofif3	# if error < 0 do
		
		lw $t0 20($sp)		# get offsetY
		add $s1 $s1 $t0		# y = y + offsetY
		sw $s1 4($sp)		# set y
		
		lw $t0 24($sp)		# get dX
		
		add $t0 $t0 $t0		# 2dX
		
		lw $t1 40($sp)		# get error
		add $t1 $t1 $t0		# error = error + 2dX
		sw $t1 40($sp)		# set error
		
endofif3:	
		
		lw $t0 16($sp)		# get offsetX
		add $s0 $s0 $t0		# x = x + offsetX
		sw $s0 0($sp)		# change stack value of x
		
		jal drawPoint
		
		bne $s0 $s2 while
end:				

		

else:		
		
		lw $t0 28($sp)		# get dY
		sw $t0 40($sp)		# set error = dy
		
while2:		beq $s1 $s3 end2 	# while y0 != y1 do

		lw $t0 24($sp)		# get dX
		add $t0 $t0 $t0		# 2dX
		
		lw $t1 40($sp)		# get error
		
		sub $t1 $t1 $t0		# error = error - 2dX
		
		sw $t1 40($sp)		# set error
		
		bgt $t1 -1 endofif4	# if error < 0
		
		lw $t0 16($sp)		# get offset x
		add $s0 $s0 $t0		# x = x + offsetX
		sw $s0 0($sp)		# change stack value of x
		
		lw $t0 28($sp)		# get dY
		add $t0 $t0 $t0		# 2dY
		
		lw $t1 40($sp)		# get error
		
		add $t0 $t1 $t0		# Error = error + 2dY
		sw $t0 40($sp)		# Set error
		
endofif4:	

		lw $t0 20($sp)		# get offsetY
		
		add $s1 $s1 $t0		# y = y + offsetY
		sw $s1 4($sp)		# change stack value of y
		
		jal drawPoint
		
		bne $s1 $s3 while2
end2:		

		
		lw  $ra 32($sp)		
		jr $ra
		
###############################################################
# void mulMatrixVec( float* M, float* vec, float* result )
mulMatrixVec:

		addi $sp $sp -96
		
		sw $a0 0($sp)		# store 4x4 matrix
		sw $a1 64($sp)		# store 4 component vector
		sw $a2 80($sp)		# store 4 component vector 
		
		lw $t0 64($sp)		# get X
		lw $t1 0($sp)		# get X1 
		mult $t0 $t1 		# multiply X * X1
		mflo $s0 		# store X * X1
		
		lw $t0 68($sp)		# get Y
		lw $t1 16($sp)		# get Y1
		mult $t0 $t1		# multiply Y * Y1
		mflo $s1		# store Y * Y1
		
		lw $t0 72($sp)		# get Z
		lw $t1 32($sp)		# get Z1
		mult $t0 $t1		# multiply Z * Z1
		mflo $s2		# store Z * Z1 
		
		lw $t0 74($sp)		# get W
		lw $t1 48($sp)		# get T1
		mult $t0 $t1		# multiply W * T1
		mflo $s3		# store W * T1
		
		add $s0 $s0 $s1
		add $s0 $s0 $s2
		add $s0 $s0 $s3		# x'
		
		sw $s0 80($sp)		# store x' 
		
		lw $t0 64($sp)		# get X
		lw $t1 4($sp)		# get X2 
		mult $t0 $t1 		# multiply X * X2
		mflo $s0 		# store X * X2
		
		lw $t0 68($sp)		# get Y
		lw $t1 20($sp)		# get Y2
		mult $t0 $t1		# multiply Y * Y2
		mflo $s1		# store Y * Y2
		
		lw $t0 72($sp)		# get Z
		lw $t1 36($sp)		# get Z2
		mult $t0 $t1		# multiply Z * Z2
		mflo $s2		# store Z * Z2
		
		lw $t0 74($sp)		# get W
		lw $t1 52($sp)		# get T2
		mult $t0 $t1		# multiply W * T2
		mflo $s3		# store W * T2
		
		add $s0 $s0 $s1
		add $s0 $s0 $s2
		add $s0 $s0 $s3		# y'
		
		sw $s0 84($sp)		# store y'
		
		lw $t0 64($sp)		# get X
		lw $t1 8($sp)		# get X3 
		mult $t0 $t1 		# multiply X * X3
		mflo $s0 		# store X * X3
		
		lw $t0 68($sp)		# get Y
		lw $t1 24($sp)		# get Y3
		mult $t0 $t1		# multiply Y * Y3
		mflo $s1		# store Y * Y3
		
		lw $t0 72($sp)		# get Z
		lw $t1 40($sp)		# get Z3
		mult $t0 $t1		# multiply Z * Z3
		mflo $s2		# store Z * Z3 
		
		lw $t0 74($sp)		# get W
		lw $t1 56($sp)		# get T3
		mult $t0 $t1		# multiply W * T3
		mflo $s3		# store W * T3
		
		add $s0 $s0 $s1
		add $s0 $s0 $s2
		add $s0 $s0 $s3		# z'
		
		sw $s0 88($sp)		# store z' 
		
		lw $t0 64($sp)		# get X
		lw $t1 12($sp)		# get X4 
		mult $t0 $t1 		# multiply X * X4
		mflo $s0 		# store X * X4
		
		lw $t0 68($sp)		# get Y
		lw $t1 28($sp)		# get Y4
		mult $t0 $t1		# multiply Y * Y4
		mflo $s1		# store Y * Y4
		
		lw $t0 72($sp)		# get Z
		lw $t1 44($sp)		# get Z4
		mult $t0 $t1		# multiply Z * Z4
		mflo $s2		# store Z * Z4
		
		lw $t0 74($sp)		# get W
		lw $t1 60($sp)		# get T4
		mult $t0 $t1		# multiply W * T4
		mflo $s3		# store W * T4
		
		add $s0 $s0 $s1
		add $s0 $s0 $s2
		add $s0 $s0 $s3		# w'
		
		sw $s0 92($sp)		# store w'
		
		
		
		
		
		
		
		

		jr $ra
        
###############################################################
# (int x,int y) = point2Display( float* vec )
point2Display:        

		la $t0 ($a0)		# get component vector
		
		#div.s $f0 $t0 $t3 	# x/w
		#cvt.w.s $f0 $f0		# x/w converted to word
		#mfc1 $t4 $f0		# move x from coprocessor
		
		#div.s $f0 $t1 $t3	# y/w
		#cvt.w.s $f0 $f0		# y/w converted to word
		#mfc1 $t5 $f0		# move y from coprocessor
		
	        jr $ra
        
###############################################################
# draw3DLines( float* lineData, int lineCount )
draw3DLines:
		
		



                jr $ra

###############################################################
# rotate3DLines( float* lineData, int lineCount )
rotate3DLines:
		jr $ra        
        
        
        
        
        
###############################################################
# void loadLineData( char* filename, float* data, int* count )
#
# Loads the line data from the specified filename into the 
# provided data buffer, and stores the count of the number 
# of lines into the provided int pointer.  The data buffer 
# must be big enough to hold the data in the file being loaded!
#
# Each line comes as 8 floats, x y z w start point and end point.
# This function does some error checking.  If the file can't be opened, it 
# forces the program to exit and prints an error message.  While other
# errors may happen on reading, note that no other errors are checked!!  
#
# Temporary registers are used to preserve passed argumnets across
# syscalls because argument registers are needed for passing information
# to different syscalls.  Temporary usage:
#
# $t0 int pointer for line count,  passed as argument
# $t1 temporary working variable
# $t2 filedescriptor
# $t3 number of bytes to read
# $t4 pointer to float data,  passed as an argument
#
loadLineData:	move $t4 $a1 		# save pointer to line count integer for later		
		move $t0 $a2 		# save pointer to line count integer for later
			     		# $a0 is already the filename
		li $a1 0     		# flags (0: read, 1: write)
		li $a2 0     		# mode (unused)
		li $v0 13    		# open file, $a0 is null-terminated string of file name
		syscall			# $v0 will contain the file descriptor
		slt $t1 $v0 $0   	# check for error, if ( v0 < 0 ) error! 
		beq $t1 $0 skipError
		la $a0 errorMessage 
		li $v0 4    		# system call for print string
		syscall
		li $v0 10    		# system call for exit
		syscall
skipError:	move $t2 $v0		# save the file descriptor for later
		move $a0 $v0         	# file descriptor (negative if error) as argument for write
  		move $a1 $t0       	# address of buffer to which to write
		li  $a2 4	    	# number of bytes to read
		li  $v0 14          	# system call for read from file
		syscall		     	# v0 will contain number of bytes read
		
		lw $t3 0($t0)	     	# read line count from memory (was read from file)
		sll $t3 $t3 5  	     	# number of bytes to allocate (2^5 = 32 times the number of lines)			  		
		
		move $a0 $t2		# file descriptor
		move $a1 $t4		# address of buffer 
		move $a2 $t3    	# number of bytes 
		li  $v0 14           	# system call for read from file
		syscall               	# v0 will contain number of bytes read

		move $a0 $t2		# file descriptor
		li  $v0 16           	# system call for close file
		syscall		     	
		
		jr $ra        
