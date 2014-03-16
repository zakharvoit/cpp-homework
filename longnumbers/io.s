section .text
		
global putstr, readchar

;;; Puts string to stdout.
;;; 	rsi -- string
;;; 	rdx -- size of string
putstr:
		push rax
		push rdi

		;; call sys_write
		mov rax, 1
		mov rdi, 1
		syscall

		pop rdi
		pop rax
		ret
		
;;; Reads char fom stdin.
;;; 	returns rax -- read char or -1 in case of failure.
readchar:
		push rdi
		push rsi
		push rdx
		sub rsp, 1

		mov rax, 0
		mov rdi, 0
		mov rsi, rsp
		mov rdx, 1
		syscall
		
		cmp rax, 1
		jne .error

		;; OK
		xor rax, rax
		mov al, [rsp]
	
		jmp .end
.error:
		mov rax, -1
.end:
		add rsp, 1
		pop rdx
		pop rsi
		pop rdi
		ret
		
