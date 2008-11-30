;; Funcoes de insercao, no vetor 'linha_de_comando': um endereco de mem ou reg,
;; de acordo com as especificacoes
;; Entrada:	DI <- posicao do byte 'mod r/m reg'
;; 		BX <- posicao do vetor 'linha_de_comando' para o proximo caracter
;; Saidas:	CX <- numero total de letras em 'linha_de_comando'
;; 		DI <- posicao para a proxima instrucao
	
;; reg16/mem16, reg16
InsereRM-Destino-16:
	push si
	mov al, byte[es:bin + di] ; al <- byte 'mod reg r/m'
	mov ah, al
	and ah, 11000000b	; ah <- apenas os 2 bits de mod
	cmp ah, 11000000b
	je InsereRM-Destino-16-mod11
	
	;; r/m indica o tipo de referencia para a memoria
	mov word[linha_de_comando + bx], 'wo'
	mov word[linha_de_comando + bx + 2], 'rd'
	add bx, 4
	call InsereMemoria	; insere "[...]" no vetor
	mov word[linha_de_comando + bx], ', '
	;; si <- 2 * reg
	mov si, ax
	and si, 0000000000111000b
	shr si, 3
	or si, 0x0008
	shl si, 1
	;; escrita
	mov cx, word[vetor_registradores + si]
	mov word[linha_de_comando + bx + 2], cx
	mov byte[linha_de_comando + bx + 4], 10
	;; cx <- numero total de caracteres na linha de comando
	mov cx, bx
	add cx, 5
	;; recupera si
	pop si
	inc di
	ret


;; r/m eh tratado como um registrador
InsereRM-Destino-16-mod11:
	;; si <- 2 * r/m
	mov si, ax
	and si, 0000000000000111b
	or si, 0x0008
	shl si, 1
	;; escrita
	mov cx, word[vetor_registradores + si]
	mov word[linha_de_comando + bx], cx
	mov word[linha_de_comando + bx + 2], ', '
	;; si <- 2 * reg
	mov si, ax
	and si, 0000000000111000b
	shr si, 3
	or si, 0x0008
	shl si, 1
	;; escrita
	mov cx, word[vetor_registradores + si]
	mov word[linha_de_comando + bx + 4], cx
	mov byte[linha_de_comando + bx + 6], 10
	;; cx <- numero total de caracteres na linha de comando
	mov cx, bx
	add cx, 7
	;; recupera si
	pop si
	inc di
	ret



;; Funcao que insere a memoria referenciada na linha de comando
;; Entrada:	BX <- inicio para a escrita
;;		DI <- indice para o byte 'mod reg r/m'
;; 		AL <- byte 'mod reg r/m'
;; Saida:	BX <- inicio para a escrita posterior
;;		DI <- indice para a proxima instrucao
InsereMemoria:
	mov byte[linha_de_comando + bx],'['





	mov byte[linha_de_comando + bx], ']'
	add bx, 1
	ret