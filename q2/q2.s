# Register Roles (Informal):
# s0: heap pointer to 1e8 numbers.
# s1: heap pointer to store the answers.
# s2: holds the value of N.
# s3: heap pointer used as a stack for indices.
# s4: ptr that moves up/down the logic stack.
# s5: i as in the loop counter

    .globl main
    .data
fmt_d:     .string "%d"
fmt_space: .string "%d "
fmt_nl:    .string "%d\n"

    .text
main:
    addi sp, sp, -16
    sd ra, 8(sp)

    # 1. Get N
    la a0, fmt_d
    mv a1, sp           # Reuse stack temporarily for N
    call scanf
    lw s2, 0(sp)

    # 2. Allocate Heap (3 x 400MB approx)
    slli a0, s2, 2      # a0 = N * 4
    call malloc
    mv s0, a0           # s0 = input_arr
    slli a0, s2, 2
    call malloc
    mv s1, a0           # s1 = res_arr
    slli a0, s2, 2
    call malloc
    mv s3, a0           # s3 = logic_stack
    mv s4, s3           # s4 = stack top

    # 3. Read Input
    li s5, 0
read_loop:
    bge s5, s2, start_algo
    la a0, fmt_d
    slli t0, s5, 2
    add a1, s0, t0
    call scanf
    addi s5, s5, 1
    j read_loop

start_algo:
    addi s5, s2, -1     # i = N - 1
algo_loop:
    bltz s5, print_loop_init
    slli t0, s5, 2
    add t0, s0, t0
    lw t1, 0(t0)        # t1 = arr[i]

pop_loop:
    beq s4, s3, stack_empty
    lw t2, -4(s4)       # Peek index
    slli t0, t2, 2
    add t0, s0, t0
    lw t3, 0(t0)        # arr[peek]
    bgt t3, t1, found_greater
    addi s4, s4, -4     # Pop
    j pop_loop

found_greater:
    slli t0, s5, 2
    add t0, s1, t0
    sw t2, 0(t0)        # res[i] = peek_index
    j push_index

stack_empty:
    li t2, -1
    slli t0, s5, 2
    add t0, s1, t0
    sw t2, 0(t0)        # res[i] = -1

push_index:
    sw s5, 0(s4)
    addi s4, s4, 4
    addi s5, s5, -1
    j algo_loop

print_loop_init:
    li s5, 0
print_loop:
    bge s5, s2, exit
    slli t0, s5, 2
    add t0, s1, t0
    lw a1, 0(t0)        # Load result
    
    addi t1, s2, -1
    beq s5, t1, print_final # If last element, use newline because of that god damned format
    la a0, fmt_space
    call printf
    addi s5, s5, 1
    j print_loop

print_final:
    la a0, fmt_nl
    call printf

exit:
    ld ra, 8(sp)
    addi sp, sp, 16
    li a0, 0
    ret
