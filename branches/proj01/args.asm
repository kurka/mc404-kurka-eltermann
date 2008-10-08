SEGMENT code
..start:
	
	; pilha
	mov ax, stack
	mov ss, ax
	mov sp, stacktop
	
	;; [ds:0x80] contem o numero de caracteres no argumento
	;; [ds:0x81]  (grande...) contem os caracteres...

	mov bh, 0x00
	mov bl, [ds:0x80]			; bx <- n de caracteres no argumento
	mov byte [bx + 0x81], '$'	; é acrescentado o caractere '$' ao final do argumento
	
	mov dx, 0x81
	mov ah, 9
	int 0x21
	
	mov ah, 0x4C
	int 0x21
		
SEGMENT stack stack
	resb 256
stacktop:
