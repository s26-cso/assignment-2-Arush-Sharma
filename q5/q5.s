.globl _start
    .data
filename: .string "input.txt"
yes_msg:  .string "Yes\n"
no_msg:   .string "No\n"

    .bss
buf_left:  .space 1
buf_right: .space 1

    .text
# Register Roles:
# s0: ID of opened file
# s1: left ptr
# s2: right ptr
# t0-t3: used for syscalls and comparing chrs
_start:
    # 1. Open file: sys_openat(AT_FDCWD, "input.txt", O_RDONLY, 0)
    li a7, 56            # syscall number for openat
    li a0, -100          # AT_FDCWD
    la a1, filename      # Address of string
    li a2, 0             # O_RDONLY
    li a3, 0             
    ecall
    mv s0, a0            # Save file descriptor in s0
    
    # 2. Get file size: sys_lseek(fd, 0, SEEK_END)
    li a7, 62            # syscall number for lseek
    mv a0, s0            # fd
    li a1, 0             # offset 0
    li a2, 2             # SEEK_END
    ecall
    
    # 0 = size
    addi s2, a0, -1      # right pointer = size - 1
    li s1, 0             # left pointer = 0
    
    # Check for trailing newline. If the last byte is '\n', ignore it.
    li a7, 62
    mv a0, s0
    mv a1, s2
    li a2, 0             # SEEK_SET
    ecall
    
    li a7, 63            # sys_read
    mv a0, s0
    la a1, buf_right
    li a2, 1
    ecall
    
    lb t0, buf_right
    li t1, 10            # ASCII for '\n' is 10
    bne t0, t1, loop     # If not newline, start loop normally
    addi s2, s2, -1      # Ignore the trailing newline

loop:
    bge s1, s2, success  # If left >= right, it's a palindrome

    # Seek left pointer
    li a7, 62
    mv a0, s0
    mv a1, s1
    li a2, 0             # SEEK_SET
    ecall
    
    # Read left character
    li a7, 63
    mv a0, s0
    la a1, buf_left
    li a2, 1
    ecall

    # Seek right pointer
    li a7, 62
    mv a0, s0
    mv a1, s2
    li a2, 0             # SEEK_SET
    ecall
    
    # Read right character
    li a7, 63
    mv a0, s0
    la a1, buf_right
    li a2, 1
    ecall

    # Compare characters
    lb t0, buf_left
    lb t1, buf_right
    bne t0, t1, failure  # in mismatch case

    addi s1, s1, 1       # left++
    addi s2, s2, -1      # right--
    j loop

success:
    la a1, yes_msg
    li a2, 4             # Length of "Yes\n"
    j print_exit

failure:
    la a1, no_msg
    li a2, 3             # Length of "No\n"

print_exit:
    # sys_write(STDOUT, msg, len)
    li a7, 64            
    li a0, 1             # stdout fd
    ecall

    # Close file: sys_close(fd)
    li a7, 57
    mv a0, s0
    ecall

    # Exit program
    li a7, 93
    li a0, 0
    ecall
