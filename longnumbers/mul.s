extern new_long, delete_long, read_long, write_long, mul_long

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
		mov rdx, 1024
		call mul_long
		mov rbx, rsi
		mov rsi, rdi
		call write_long

		call delete_long
		mov rdi, rbx
		;; call delete_long
		call exit

;;; Stop program with 0 return status.
exit:	
		;; call sys_exit
		mov rax, 60
		xor rdi, rdi
		syscall
