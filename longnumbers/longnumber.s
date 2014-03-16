extern malloc, free, putstr, readchar

section .text

global new_long, delete_long, read_long, write_long
global mul_long, add_long, sub_long

;;; Create new long number in heap.
;;; 	returns rax -- created number
new_long:
		push rdx
		push rdi
		push rsi
		push r8
		push r11

		mov rdi, max_size
		call malloc

		pop r11
		pop r8
		pop rsi
		pop rdi
		pop rdx
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
		push rdx
		push rdi
		push rsi
		push r8
		push r11

		call free

		pop r11
		pop r8
		pop rsi
		pop rdi
		pop rdx
		ret
		
;;; Calculates sum of long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 	rdx -- max length of operands
;;; 
;;; 	returns rdi -- sum of operands
;;; 			rdx -- length of sum
add_long:
		push r8
		push rdi
		push rsi
		push rax
		push rbx
		push rdx

		mov r8, rdi
		xor bl, bl
.loop:
		mov al, [rsi]
		add al, [rdi]
		add al, bl
		xor bl, bl
		cmp al, radix
		jl .ok
		;; carry
		sub al, radix
		mov bl, 1
.ok:
		mov [rdi], al
		inc rdi
		inc rsi
		dec rdx
		jnz .loop

		test rbx, rbx
		jz .end
		mov byte [rdi], 1
.end:
		pop rdx

		add rdx, rbx 			; if length of numbers increased
.shrink_loop:					; if length of number decreased (actually length was less then rdx)
		cmp rdx, 1
		je .break
		cmp byte [r8 + rdx - 1], 0
		jnz .break
		dec rdx
		jmp .shrink_loop
;;; end .shrink_loop
.break:
		
		pop rbx
		pop rax
		pop rsi
		pop rdi
		pop r8
		ret
		
;;; Subtracts two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 	rdx -- max length of operands
;;; 
;;; 	returns rdi -- difference of operands
;;; 			rdx -- length of difference
sub_long:
		push rsi
		push rax
		push rbx
		push rdx
		push rdi

		xor bl, bl
.loop:
		mov al, [rdi]
		sub al, [rsi]
		sub al, bl
		xor bl, bl
		cmp al, 0
		jge .ok
		;; carry
		add al, radix
		mov bl, 1
.ok:
		mov [rdi], al
		inc rdi
		inc rsi
		dec rdx
		jnz .loop

		test bl, bl
		jz .end
		;; subtraction overflow
		mov rdx, overflow_msg_size
		mov rsi, overflow_msg
		call putstr
.end:
		pop rdi
		pop rdx
.shrink_loop:
		cmp rdx, 1
		je .break
		cmp byte [rdi + rdx - 1], 0
		jnz .break
		dec rdx
		jmp .shrink_loop
.break:
		pop rbx
		pop rax
		pop rsi
		ret

;;; Multiplies long number by a short
;;; 	rdi -- long number
;;; 	rdx -- length of number
;;; 	rbx -- short number
;;; 	returns rdx -- length of resulting number
mul_long_short:
		push rax
		push rcx
		push r8
		push r9
		push r10
		
		mov r10, radix
		mov r9, rdx
		xor r8, r8
		xor rax, rax
		xor rcx, rcx
		xor rdx, rdx
.loop:
		mov rax, rbx
		mul byte [rdi + rcx] 
		add rax, r8
		xor rdx, rdx
		div r10
		mov r8, rax
		mov [rdi + rcx], dl

		inc rcx

		test r8, r8
		jnz .loop

		cmp rcx, r9
		jl .loop
;;; end .loop

		mov rdx, rcx

		pop r10
		pop r9
		pop r8
		pop rcx
		pop rax
		ret

;;; Multiplies two long numbers.
;;; 	rdi -- first long
;;; 	rsi -- second long
;;; 	rdx -- max length of operands
;;; 
;;; 	returns rdi -- product of operands
;;; 			rdx -- length of product
mul_long:
		push r8					; long buffer
		push r9					; ptr buffer
		push r10				; length buffer
		push r11 				; long accumulator
		push rbx				; short buffer
		push rcx				; current digit index
		push rax				; power accumulator
		push r12				; one another hack

		mov r12, rsi
		
		call new_long
		mov r8, rax

		call new_long
		mov r11, rax

		mov r10, rdx
		xor rcx, rcx
		xor rax, rax
		mov r9, rdi
.loop:
		mov rsi, r12
		mov rdx, max_size
		;; begin multiplication rsi on rdi[rcx] digit.
		mov rdi, r8
		call fill_zeros
		call add_long
		mov bl, [r9 + rcx]
		call mul_long_short

		mov bl, radix
		push rcx
		xor rcx, rcx
		test rax, rax
		jz .break_power
.power:
		call mul_long_short
		inc rcx
		cmp rcx, rax
		jne .power
;;; end .power
.break_power:
		pop rcx
		;; end multiplication rsi on rdi[rcx] digit

		;; add calculated value to r11 accumulator
		push rsi
		mov rdi, r11
		mov rsi, r8
		mov rdx, max_size		; FIXME: think what is real size
		call add_long
		pop rsi
		
		inc rax
		inc rcx
		cmp rcx, r10
		jne .loop
;;; end .loop

		mov rdi, r9
		call delete_long 		; remove old value

		mov rdi, r8
		call delete_long		; remove buffer

		mov rdi, r11			; now rdi is accumulated value

		pop r12
		pop rax
		pop rcx
		pop rbx
		pop r11
		pop r10
		pop r9
		pop r8
		ret

;;; Writes long number to stdout.
;;; 	rsi -- pointer to long number
;;; 	rdx -- length of long number
write_long:
		push rsi
		push rdx

		add rsi, rdx			; rsi points to the highest digit
		dec rsi

.loop:
		call write_digit
		dec rsi
		dec rdx
		jnz .loop
;;; end .loop
		
		pop rdx
		pop rsi
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

max_size:			equ 1024
radix:				equ 10
overflow_msg:		db "Error: subtraction overflow!",0x0a
overflow_msg_size:	equ $ - overflow_msg

