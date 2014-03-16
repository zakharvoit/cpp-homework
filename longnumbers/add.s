extern new_long, delete_long, read_long, write_long, add_long

section	.text

global main

;;; Program entry point.
main:	
		call new_long
		mov rsi, rax
		mov rdi, rax
		call read_long
		mov rdx, rax
		call new_long
		mov rsi, rax
		call read_long
		cmp rdx, rax
		jnl .ok
		mov rbx, rax
		mov rax, rdx
.ok:
		call add_long
		mov r8, rsi
		mov rsi, rdi
		call write_long
		mov rsi, r8

		call delete_long
		mov rdi, rsi
		call delete_long
		call exit

;;; Stop program with 0 return status.
exit:	
		;; call sys_exit
		mov rax, 60
		xor rdi, rdi
		syscall
