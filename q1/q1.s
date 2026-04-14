.globl make_node
    .globl insert
    .globl get
    .globl getAtMost

    .text

# make_node(int val)
# Register Roles:
# a0: stores 'val' in insert, takes back the newly allocated pointer.
# s0: temporarily stores 'val' while malloc is called because a0 is not available
# ra: return address
# sp: stack pointer to save s0 and ra

make_node:
    addi sp, sp, -16
    sd ra, 8(sp)
    sd s0, 0(sp)
    
    mv s0, a0          # Save val in s0
    li a0, 24          # 24 bytes for struct (int + padding + 2 pointers)
    call malloc        # malloc(24)
    
    sw s0, 0(a0)       # root->val = val (using sw for 32-bit int)
    sd zero, 8(a0)     # root->left = NULL (8-byte pointer)
    sd zero, 16(a0)    # root->right = NULL
    
    ld s0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

# insert(struct Node* root, int val)
# Register Roles:
# a0: as arg: Brings the current node pointer, later returns the updated root
# a1: arg 2: inserted value
# s0: saves root
# s1: saves value
# t0: holds val of curr node

insert:
    bnez a0, insert_not_null # If root is not NULL, continue
    # If root is NULL, make a new node and return it
    j make_node              # Tail call to make_node

insert_not_null:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    sd s1, 8(sp)
    
    mv s0, a0          # Save root pointer
    mv s1, a1          # Save val
    
    lw t0, 0(s0)       # t0 = root->val
    blt s1, t0, insert_left # if val < root->val, go left
    
insert_right:
    ld a0, 16(s0)      # a0 = root->right
    mv a1, s1          # a1 = val
    call insert
    sd a0, 16(s0)      # root->right = insert(root->right, val)
    j insert_done
    
insert_left:
    ld a0, 8(s0)       # a0 = root->left
    mv a1, s1          # a1 = val
    call insert
    sd a0, 8(s0)       # root->left = insert(root->left, val)

insert_done:
    mv a0, s0          # Return original root
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret

# get(struct Node* root, int val)
# Register Roles:
# a0: Traverses the tree nodes, returns the found node (or NULL).
# a1: value we are searching for
# t0: holds value of the current node.

get:
    beqz a0, get_end   # If root == NULL, return NULL
    lw t0, 0(a0)        # t0 = root->val
    beq a1, t0, get_end # If val == root->val, return root
    
    blt a1, t0, get_left
    ld a0, 16(a0)      # Move to right child
    j get              # recurse
get_left:
    ld a0, 8(a0)       # Move to left child
    j get              # recurse
get_end:
    ret

# getAtMost(int val, struct Node* root)
# Register Roles:
# a0: arg1: The maximum value we are allowed to return.
# a1: curr node: the current node we are inspecting.
# s0: saves the limit value across calls.
# s1: saves the current node across calls.
# t0: curr node->val

getAtMost:
    bnez a1, gam_not_null
    li a0, -1          # Return -1 if root == NULL
    ret
gam_not_null:
    lw t0, 0(a1)       # t0 = root->val
    beq t0, a0, gam_exact # If exact match, return val
    
    blt a0, t0, gam_left  # If limit < root->val, MUST go left
    
    # Otherwise, it might be this node, or a larger valid one to the right
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    sd s1, 8(sp)
    
    mv s0, a0          # Save limit
    mv s1, a1          # Save current node
    
    # Try finding a better one in the right subtree
    ld a1, 16(s1)      # a1 = root->right
    call getAtMost
    
    li t0, -1
    bne a0, t0, gam_done # If right subtree found something valid, return it!
    
    # If right subtree failed (returned -1), this current node is the best
    lw a0, 0(s1)       # a0 = root->val
    
gam_done:
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret
    
gam_left:
    ld a1, 8(a1)       # Go left
    j getAtMost        # Tail recursion
gam_exact:
    # a0 already holds val, just return
    ret
