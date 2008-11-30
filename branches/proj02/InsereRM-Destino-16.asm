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
	mov ah, al
	and ah, 00000111b
	
	cmp ah, 00000000b
	je InsereMemoria000
	cmp ah, 00000001b
	je InsereMemoria001
	cmp ah, 00000010b
	je InsereMemoria010
	cmp ah, 00000011b
	je InsereMemoria011
	cmp ah, 00000100b
	je InsereMemoria100
	cmp ah, 00000101b
	je InsereMemoria101
	cmp ah, 00000110b
	je InsereMemoria110
	cmp ah, 00000111b
	je InsereMemoria111

InsereMemoria000:	
	mov word[linha_de_comando + bx + 1],'BX'
	mov byte[linha_de_comando + bx + 3],'+'
	mov word[linha_de_comando + bx + 4],'SI'
	add bx, 6
	jmp FimInsereMemoria
InsereMemoria001:	
	mov word[linha_de_comando + bx + 1],'BX'
	mov byte[linha_de_comando + bx + 3],'+'
	mov word[linha_de_comando + bx + 4],'DI'
	add bx, 6
	jmp FimInsereMemoria
InsereMemoria010:	
	mov word[linha_de_comando + bx + 1],'BP'
	mov byte[linha_de_comando + bx + 3],'+'
	mov word[linha_de_comando + bx + 4],'SI'
	add bx, 6
	jmp FimInsereMemoria
InsereMemoria011:
	mov word[linha_de_comando + bx + 1],'BP'
	mov byte[linha_de_comando + bx + 3],'+'
	mov word[linha_de_comando + bx + 4],'DI'
	add bx, 6
	jmp FimInsereMemoria
InsereMemoria100:
	mov word[linha_de_comando + bx + 1],'SI'
	add bx, 3
	jmp FimInsereMemoria
InsereMemoria101:	
	mov word[linha_de_comando + bx + 1],'DI'
	add bx, 3
	jmp FimInsereMemoria
InsereMemoria110:
	mov word[linha_de_comando + bx + 1],'BP'
	add bx, 3
	jmp FimInsereMemoria
InsereMemoria111:
	mov word[linha_de_comando + bx + 1],'BX'
	add bx, 3
	jmp FimInsereMemoria
	
FimInsereMemoria:
	call InsereDeslocamento
	mov byte[linha_de_comando + bx], ']'
	add bx, 1
	ret


;; Entradas: BX, DI, AL
;; Saidas: BX, DI
InsereDeslocamento:
	mov ah, al
	and ah, 11000000b

	cmp ah, 00000000b
	je InsereDeslocamento00
	cmp ah, 01000000b
	je InsereDeslocamento01
	cmp ah, 10000000b
	je InsereDeslocamento10
	
;; disp=0 (exceto para r/m=110)
InsereDeslocamento00:
	mov ah, al
	and ah, 00000111b
	cmp ah, 00000110
	je InsereDeslocamento10
	ret
	
;; disp=(disp-low)
InsereDeslocamento01:
	mov byte[linha_de_comando + bx], '+'
	mov byte[linha_de_comando + bx + 1], '0'
	push ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + bx + 2], ax
	mov byte[linha_de_comando + bx + 4], 'h'
	pop ax
	add bx, 5
	ret

;; disp=(disp-high):(disp-low)
InsereDeslocamento10:
	mov byte[linha_de_comando + bx], '+'
	mov byte[linha_de_comando + bx + 1], '0'
	push ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + bx + 4], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + bx + 2], ax
	mov byte[linha_de_comando + bx + ], 'h'
	pop ax
	add bx, 7
	ret

