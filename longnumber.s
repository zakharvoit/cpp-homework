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

;;; Clears long number.
;;; 	rdi -- long number to clear
clear:
		push rcx
		push rbx

		mov rbx, max_size
		shr rbx, 3
		xor rcx, rcx
.loop:
		mov qword [rdi + rcx * 8], 0
		inc rcx
		cmp rcx, rbx
		jl .loop

		pop rbx
		pop rcx
		ret
		
;;; Copy one long number to another.
;;; 	rsi -- source long number
;;; 	rdi -- destination long number
;;; 	rdx -- length of source long number
copy_long:		
		push rcx 				; loop counter
		push rbx

		call clear
		
		xor rcx, rcx
.loop:
		mov bl, [rsi + rcx]
		mov [rdi + rcx], bl
		inc rcx
		cmp rcx, rdx
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
;;; 	rdx -- length of arguments
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
		cmp rcx, rdx
		jl .not_trash
		xor al, al
.not_trash:
		mov al, [rsi + rcx]
		add al, [rdi + rcx]
		add al, bl
		xor bl, bl

		cmp al, radix
		jl .ok
		sub al, radix
		mov bl, 1
.ok:
		mov [rdi + rcx], al
		
		inc rcx
		cmp rcx, rdx
		jl .loop

		test bl, bl
		jnz .loop

		mov rdx, rcx
		
		pop rbx
		pop rax
		pop rcx
		ret
		
;;; Subtracts two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 	rdx -- size of numbers
;;; 
;;; 	returns rdi -- difference of operands
;;;				rdx -- size of difference
sub_long:
		push rcx				; index of current digit
		push rbx				; carry flag
		push rax				; calculation buffer

		xor rcx, rcx
		xor rbx, rbx
.loop:
		cmp rcx, rdx
		jl .not_trash
		xor al, al
		jmp .trash
.not_trash:
		mov al, [rdi + rcx]
		sub al, [rsi + rcx]
.trash:
		sub al, bl
		xor bl, bl

		cmp al, 0
		jge .ok
		add al, radix
		mov bl, 1
.ok:
		mov [rdi + rcx], al

		inc rcx
		cmp rcx, rdx
		jl .loop

		test bl, bl
		jnz .loop

.shrink:						; remove leading zeros
		cmp rdx, 1
		je .break
		cmp byte [rdi + rdx - 1], 0
		jne .break
		dec rdx
		jmp .shrink
.break:
		
		pop rax
		pop rbx
		pop rcx
		ret

;;; Multiplies long number by a short
;;; 	rdi -- long number
;;; 	rbx -- short number
;;; 	rdx -- length of long number
;;; 
;;; 	returns rdi -- product of operands
;;; 			rdx -- length of product
mul_long_short:
		push rcx			; index of current digit
		push rax			; calculation buffer
		push r8				; swap buffer
		push r9				; length buffer
		;; rdx used as carry

		mov r9, rdx
		xor rcx, rcx
		xor rdx, rdx
		xor rax, rax
.loop:
		mov al, [rdi + rcx]
		cmp rcx, r9				; check if rcx is less then size
		jl .not_trash
		xor rax, rax
.not_trash:
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
		cmp rcx, r9
		jl .loop
		test rdx, rdx
		jnz .loop
.end:

		mov rdx, rcx

.shrink:						; if one of operands was zero, size will be 0
		cmp rdx, 1
		je .break
		cmp byte [rdi + rdx - 1], 0
		jne .break
		dec rdx
		jmp .shrink
.break:

		pop r9
		pop r8
		pop rax
		pop rcx
		ret
		
;;; Multiplies two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 	rdx -- length of operands
;;; 
;;; 	returns rdi -- product of operands
;;; 			rdx -- length of product
mul_long:
		push rcx				; index of current digit
		push rax				; used for calling other functions
		push rbx				; used for calling other functions
		push r8					; long buffer
		push r9					; long accumulator
		push r10 				; buffer for rdi
		push r11				; buffer for length of rdi
		push r12 				; buffer for length of r9

		mov r10, rdi

		call new_long
		mov r8, rax

		call new_long
		mov r9, rax
		
		xor r12, r12
		mov r11, rdx
		xor rcx, rcx
		xor rbx, rbx
.loop:
		mov rdi, r8
		mov rdx, r11
		call copy_long

		mov bl, [r10 + rcx]
		call mul_long_short

		mov rbx, rcx
		call power_long_radix

		push rsi
		mov rsi, r8
		mov rdi, r9
		cmp r12, rdx
		jl .less
		mov rdx, r12
.less:
		call add_long
		mov r12, rdx
		pop rsi
		
		inc rcx
		cmp rcx, r11
		jne .loop

		mov rdi, r8
		call delete_long

		mov rdi, r10
		call delete_long

		mov rdi, r9 			; return accumulated value
		mov rdx, r12			; and length
		
		pop r12
		pop r11
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
;;; 	rdx -- length of long number
;;; 
;;;     returns rdi -- result
;;; 			rdx -- length of result	
power_long_radix:
		push rcx				; loop counter
		push rax				; swap buffer

		lea rcx, [rdi + rdx]
		dec rcx

		cmp rdx, 1
		jne .loop
		cmp byte [rdi], 0
		je .end
.loop:
		mov al, [rcx]
		mov byte [rcx], 0
		mov [rcx + rbx], al
		dec rcx
		cmp rcx, rdi
		jge .loop

		add rdx, rbx
.end:
		
		pop rax
		pop rcx
		ret

;;; Writes long number to stdout.
;;; 	rsi -- pointer to long number
;;; 	rdx -- length of number
write_long:
		push rax				; length of buffer
		push rsi
		push rdx

		mov rax, rsi
		add rsi, rdx			; now rsi points to end of number

.loop:
		dec rsi
		call write_digit
		cmp rax, rsi
		jne .loop
		
		pop rdx
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
;;; 	returns rdx -- length of resulting number
read_long:
		push rbx
		push rax

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

		pop rax
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

max_size:			equ 2048
radix:				equ 10

