extern malloc, free, putstr, readchar

section .text

global new_long, delete_long, read_long, write_long
global mul_long, add_long, sub_long

;;; Create new long number in heap.
;;; 	returns rax -- created number
new_long:
		push rsi				; malloc can use any register
		push rdi				; so, we should push all
		push rbx				; and there are no pusha
		push rcx				; in x86_64
		push rdx
		push r8
		push r9
		push r10
		push r11
		push r12
		push r13
		push r14
		push r15

		mov rdi, max_size
		call malloc

		pop r15
		pop r14
		pop r13
		pop r12
		pop r11
		pop r10
		pop r9
		pop r8
		pop rdx
		pop rcx
		pop rbx
		pop rdi
		pop rsi
		ret

;;; Fills long number by zeros.
;;; 	rdi -- long number to fill
fill_zeros:		
		push rcx
		push rbx

		xor rcx, rcx
		mov rbx, max_size
		shr rbx, 3
.loop:
		mov qword [rdi + rcx * 8], 0

		inc rcx
		cmp rcx, rbx
		jne .loop
		
		pop rbx
		pop rcx
		ret

;;; Deletes long number.
;;; 	rdi -- number to delete
delete_long:
		push rsi
		push rax
		push rbx
		push rcx
		push rdx
		push r8
		push r9
		push r10
		push r11
		push r12
		push r13
		push r14
		push r15

		call free

		pop r15
		pop r14
		pop r13
		pop r12
		pop r11
		pop r10
		pop r9
		pop r8
		pop rdx
		pop rcx
		pop rbx
		pop rax
		pop rsi
		ret
		
;;; Returns length of long number.
;;; 	rsi -- long number
;;; 	returns rax -- length
long_length:	
		lea rax, [rsi + max_size]

.loop:
		dec rax
		cmp rax, rsi
		je .break
		cmp byte [rax], 0
		je .loop
.break:
		sub rax, rsi
		inc rax

		ret

;;; Calculates sum of long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 
;;; 	returns rdi -- sum of operands
;;; 			rdx -- length of sum
add_long:
		push rcx				; index of current digit
		push rax				; calculation buffer
		push rbx				; carry flag

		xor al, al
		xor bl, bl
		xor rcx, rcx
.loop:
		mov al, [rsi + rcx]
		add al, [rdi + rcx]
		add al, bl
		xor bl, bl

		cmp al, 10
		jl .ok
		sub al, 10
		mov bl, 1
.ok:
		mov [rdi + rcx], al
		
		inc rcx
		cmp rcx, max_size
		jne .loop
		
		pop rbx
		pop rax
		pop rcx
		ret
		
;;; Subtracts two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 
;;; 	returns rdi -- difference of operands
sub_long:
		push rcx				; index of current digit
		push rbx				; carry flag
		push rax				; calculation buffer

		xor rcx, rcx
		xor rbx, rbx
.loop:
		mov al, [rdi + rcx]
		sub al, [rsi + rcx]
		sub al, bl
		xor bl, bl

		cmp al, 0
		jge .ok
		add al, 10
		mov bl, 1
.ok:
		mov [rdi + rcx], al

		inc rcx
		cmp rcx, max_size
		jne .loop
		
		pop rax
		pop rbx
		pop rcx
		ret

;;; Multiplies long number by a short
;;; 	rdi -- long number
;;; 	rbx -- short number
;;; 
;;; 	returns rdi -- product of operands
mul_long_short:
		push rcx			; index of current digit
		push rdx			; carry
		push rax			; calculation buffer
		push r8				; swap buffer

		xor rcx, rcx
		xor rdx, rdx
		xor rax, rax
.loop:
		mov al, [rdi + rcx]
		mul bl
		add rax, rdx
		xor rdx, rdx
		cmp rax, radix
		jl .ok

		mov r8, radix
		div r8
		mov r8, rax
		mov rax, rdx
		mov rdx, r8
.ok:
		mov [rdi + rcx], al
		inc rcx
		cmp rcx, max_size
		jne .loop

		pop r8
		pop rax
		pop rdx
		pop rcx
		ret
		
;;; Multiplies two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 
;;; 	returns rdi -- product of operands
mul_long:
		push rcx				; index of current digit
		push rax				; used for calling other functions
		push rbx				; used for calling other functions
		push r8					; long buffer
		push r9					; long accumulator
		push r10 				; buffer for result

		mov r10, rdi

		call new_long
		mov r8, rax

		call new_long
		mov r9, rax
		
		xor rcx, rcx
		xor rbx, rbx
.loop:
		mov rdi, r8
		call fill_zeros
		call add_long

		mov bl, [r10 + rcx]
		call mul_long_short

		mov rbx, rcx
		call power_long_radix

		push rsi
		mov rsi, r8
		mov rdi, r9
		call add_long
		pop rsi
		
		inc rcx
		cmp rcx, max_size
		jne .loop

		mov rdi, r8
		call delete_long

		mov rdi, r10
		call delete_long

		mov rdi, r9 			; return accumulated value
		
		pop r10
		pop r9
		pop r8
		pop rbx
		pop rax
		pop rcx
		ret

;;; Raise long number by power radix * short number
;;; 	rdi -- long number
;;;     rbx -- short number
;;; 
;;;     result rdi -- result
power_long_radix:
		push rcx 				; loop counter
		push rdx 				; buffer for length

		mov rdx, rbx
		xor rcx, rcx
		cmp rcx, rbx
		je .break				
.loop:
		mov rbx, 10
		call mul_long_short

		inc rcx
		cmp rcx, rdx
		jne .loop
.break:

		pop rbx
		pop rcx
		ret

;;; Writes long number to stdout.
;;; 	rsi -- pointer to long number
write_long:
		push rax				; length of buffer
		push rsi

		call long_length
		add rsi, rax			; now rsi points to end of number

		pop rax
		push rax				; now rax points to begin of number
.loop:
		dec rsi
		call write_digit
		cmp rax, rsi
		jne .loop
		
		pop rsi 
		pop rax
		ret

;;; Writes digit to stdout.
;;; 	rsi -- pointer to digit
write_digit:
		push rdx
		
		add byte [rsi], '0'
		mov rdx, 1
		call putstr
		sub byte [rsi], '0'

		pop rdx
		ret

;;; Reads long number.
;;; 	rsi -- pointer to long number
;;; 	returns rax -- length of resulting number
read_long:
		push rbx
		push rdx

		mov rbx, rsi
.loop:
		call readchar
		cmp rax, -1
		je .break
		cmp rax, ' '
		je .break
		cmp rax, 0x0a
		je .break
		sub al, '0'
		mov [rbx], rax
		inc rbx
		jmp .loop
;;; end .loop
.break:							
		
		sub rbx, rsi
		mov rax, rbx

		mov rdx, rax
		call reverse

		pop rdx
		pop rbx
		ret

;;; Reverse bytes array.
;;; 	rsi -- array
;;; 	rdx -- length
reverse:		
		push rdx
		push rsi
		push rax
		push rbx

		add rdx, rsi
		dec rsi

.loop:
		inc rsi
		dec rdx

		cmp rsi, rdx
		jg .break
		
		mov al, [rsi]
		mov bl, [rdx]
		mov [rsi], bl
		mov [rdx], al

		jmp .loop
;;; end .loop
.break:
		
		pop rbx
		pop rax
		pop rsi
		pop rdx
		ret

section .rodata

max_size:			equ 512
radix:				equ 10
overflow_msg:		db "Error: subtraction overflow!",0x0a
overflow_msg_size:	equ $ - overflow_msg

