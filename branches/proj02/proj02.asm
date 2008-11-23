SEGMENT code
..start:

	;; inicializa segmento de pilha
	mov ax, stack
	mov ss, ax
	mov sp, stacktop


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	xor bx, bx
	mov bl, [ds:0x80]		;; bl <- numero de caracteres do argumento (contando espaco)
	mov byte[ds:0x81+bx], 0x00	;; nome do arquivo deve terminar com o byte 0x00 (ASCIIZ)

	mov ah, 0x3D			;; serviço do DOS de abertura de arquivo
	mov al, 0			;; modo de abertura: read-only
	mov dx, 0x82			;; offset para o primeiro caractere do nome do arquivo
	int 0x21
	mov bx, ax			;; bx <- handle do arquivo aberto
	
	;; inicializa segmento de dados
	mov ax, data
	mov ds, ax
	
	;; verificar a flag Carry
	jc ErroAbreArquivo
	;; se chegar até aqui, o arquivo abriu normalmente e BX contem o handle para o arquivo de entrada
	jmp CarregaCom
	
ErroAbreArquivo:
	mov ah, 9
	mov dx, MsgErroAbreArquivo
	int 0x21			;; exibe msg de erro
	jmp Fim				;; termina a execução do programa
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; leitura do arquivo executavel para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CarregaCom:	
	;; tamanho maximo do arquivo .COM = 64k bytes
	;; portanto, iremos copia-lo inteiro no segmento extra de dados (ES)

	;; inicializacao de ES
	mov ax, data2
	mov es, ax

	;; move o file-pointer para o final do arquivo
	mov ah, 0x42
	;; bx continua contendo o handle para o arquivo
	xor cx, cx
	xor dx, dx		; cx e dx <-  0x0000
	mov al, 2		; move a partir do fim do arquivo
	int 0x21
	;; guarda o tamanho do arquivo em bytes na memoria
	mov [tam_arq_com], ax

	;; para a leitura, o file-pointer sera novamente movido ao inicio do arquivo
	mov ah, 0x42
	;; bx continua contendo o handle para o arquivo
	;; cx == dx == 0x0000
	mov al, 0		; move a partir do começo do arquivo
	int 0x21

	;; cx <- tamanho do arquivo em bytes
	mov cx, [tam_arq_com]
	
	;; colocaremos o valor de ES temporariamente em DS
	push ds			; guarda ds na pilha
	mov ax, es
	mov ds, ax
	mov dx, bin		; DS:DX <- "ES:bin"
	mov ah, 0x3F 		; leitura
	;; bx continua contendo o handle para o arquivo
	int 0x21		; arquivo eh salvo INTEIRO na memoria no segmento ES
	
	;; recupera ds
	pop ds

	;; fecha o arquivo de entrada
	mov ah, 0x3E
	;; bx continua contendo o handle para o arquivo
	int 0x21
	jmp AbreArquivoSaida
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; leitura do arquivo executavel para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________ 


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
AbreArquivoSaida:	
	
	;; criacao do arquivo de saida (que contera o codigo do programa)
	mov ah, 0x3C
	xor cx, cx 		; cx <- 0x0000
	mov dx, arq_saida	; dx aponta para o nome do arquivo
	int 0x21
	mov [handle_arq_out],ax	; salva o handle do arquivo de saida na memoria

	jmp Principal
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; escrita das instrucoes ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Principal:	

	;; escreve o inicio do codigo no arquivo de saida
	;; linha_de_comando recebe as primeiras diretrizes em sua definicao
	;; org 100h
	;; section .text
	;; start:
	mov cx, 30
	call Imprime
	

	;; Para percorrer todos os bytes do arquivo executavel, o registrador DI sera
	;; usado como indice de acesso
	
	push si
	push di			; salva di na pilha
	xor di, di		; di <- 0x0000
	xor si,si
	
WhileInstrucoes:	
	;; Interpretacao dos bytes do arquivo binario:
	;; Usaremos uma tabela com enderecos de trechos do codigo (do segmento CS).
	;; Para isso, a indexacao da tabela eh feita diretamente com o byte do arquivo .COM

	;; BX sera usado como o indice para a tabela
	xor bx, bx		; bx <- 0x0000
	mov bl, byte[es:bin + di]	; bl <- byte do arquivo executavel
	shl bx, 1		; bx <- bx*2
	call [Table + bx]	; chamada da rotina para a instrucao especifica
	call Imprime		; escreve a linha de comando no arquivo de saida

	inc di
	
	;; caso si seja igual a 1, entao acabaram as instrucoes e iniciarao os dados
	cmp si, 1
	je WhileDados

	;; caso o di ainda nao tenha percorrido todo o arquivo .COM, executa novamente
	;; para o proximo comando	
	cmp di, [tam_arq_com]
	jne WhileInstrucoes
	;; caso contrario, termina a execucao
	jmp Fim

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; escrita das instrucoes ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;
	;; escrita dos dados ;;
	;;;;;;;;;;;;;;;;;;;;;;;

WhileDados:
	mov cx, 8
	mov word[linha_de_comando], 'db'
	mov word[linha_de_comando + 2], ' 0'
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7],10
	
WhileDados1:	
	call HexToAscii
	mov word[linha_de_comando + 4], ax
	call Imprime
	inc di
	cmp di, [tam_arq_com]
	jne WhileDados1
	jmp Fim

	;;;;;;;;;;;;;;;;;;;;;;;
	;; escrita dos dados ;;
	;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; tabela das rotinas para cada instrucao ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Cada funcao, quando chamada, deve retornar o vetor 'linha_de_comando' montado
	;; de acordo com a instrucao do byte lido. Alem disso, retorna tambem no registrador
	;; CX o numero de caracteres a serem escritos (incluindo o byte 10 <nova linha>)
	
case00:
case01:
case02:
case03:
case04:
case05:
;;push es
case06:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' E'  
	mov byte[linha_de_comando + 6],'S'
	mov byte[linha_de_comando + 7],10	
	ret
;;pop es
case07:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'ES'  
	mov byte[linha_de_comando + 6],10	
	ret	
case08:
case09:
case0A:
case0B:

;;or AL, XYh
case0C:
	mov cx, 12
	mov word[linha_de_comando], 'or'
	mov word[linha_de_comando + 2], '  '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;or AX, XYZWh
case0D:
	mov cx,14 
	mov word[linha_de_comando], 'or'
	mov word[linha_de_comando + 2], '  '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
;;pop cs
case0E:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' C'  
	mov byte[linha_de_comando + 6],'S'
	mov byte[linha_de_comando + 7],10	
	ret	
;;; Funcao invalida para processador 80X86
case0F:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 0'
	mov word[linha_de_comando + 4],'Fh'
	mov byte[linha_de_comando + 6],10
	ret 


case10:
case11:
case12:
case13:

;;adc AL, XYh
case14:
	mov cx, 12
	mov word[linha_de_comando], 'ad'
	mov word[linha_de_comando + 2], 'c '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;adc AX, XYZWh
case15:
	mov cx,14 
	mov word[linha_de_comando], 'ad'
	mov word[linha_de_comando + 2], 'c '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10

;;push ss
case16:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' S'  
	mov byte[linha_de_comando + 6],'S'
	mov byte[linha_de_comando + 7],10	
	ret
;;pop es
case17:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'SS'  
	mov byte[linha_de_comando + 6],10	
	ret	
case18:
case19:
case1A:
case1B:
;;sbb AL, XYh
case1C:
	mov cx, 12
	mov word[linha_de_comando], 'sb'
	mov word[linha_de_comando + 2], 'b '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;sbb AX, XYZWh
case1D:
	mov cx,14 
	mov word[linha_de_comando], 'sb'
	mov word[linha_de_comando + 2], 'b '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
;;push es
case1E:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' E'  
	mov byte[linha_de_comando + 6],'S'
	mov byte[linha_de_comando + 7],10	
	ret
;;pop ds
case1F:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'DS'  
	mov byte[linha_de_comando + 6],10	
	ret	
case20:
case21:
case22:
case23:
;;and AL, XYh
case24:
	mov cx, 12
	mov word[linha_de_comando], 'an'
	mov word[linha_de_comando + 2], 'd '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;and AX, XYZWh
case25:
	mov cx,14 
	mov word[linha_de_comando], 'an'
	mov word[linha_de_comando + 2], 'd '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	
;;; Funcao invalida para processador 80X86
case26:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 2'
	mov word[linha_de_comando + 4],'6h'
	mov byte[linha_de_comando + 6],10
	ret
;;; Funcao invalida para processador 80X86	
case27:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 2'
	mov word[linha_de_comando + 4],'7h'  
	mov byte[linha_de_comando + 6],10
	ret 

case28:
case29:
case2A:
case2B:
;;sub AL, XYh
case2C:
	mov cx, 12
	mov word[linha_de_comando], 'su'
	mov word[linha_de_comando + 2], 'b '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;sub AX, XYZWh
case2D:
	mov cx,14 
	mov word[linha_de_comando], 'su'
	mov word[linha_de_comando + 2], 'b '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10

;;; Funcao invalida para processador 80X86	
case2E:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 2'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case2F:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 2'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 

case30:
case31:
case32:
case33:
;;xor AL, XYh
case34:
	mov cx, 12
	mov word[linha_de_comando], 'xo'
	mov word[linha_de_comando + 2], 'r '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;xor AX, XYZWh
case35:
	mov cx,14 
	mov word[linha_de_comando], 'xo'
	mov word[linha_de_comando + 2], 'r '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10

;;; Funcao invalida para processador 80X86	
case36:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 3'
	mov word[linha_de_comando + 4],'6h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case37:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 3'
	mov word[linha_de_comando + 4],'7h'  
	mov byte[linha_de_comando + 6],10
	ret 

case38:
case39:
case3A:
case3B:
;;xor AL, XYh
case3C:
	mov cx, 12
	mov word[linha_de_comando], 'xo'
	mov word[linha_de_comando + 2], 'r '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;xor AX, XYZWh
case3D:
	mov cx,14 
	mov word[linha_de_comando], 'xo'
	mov word[linha_de_comando + 2], 'r '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10

;;; Funcao invalida para processador 80X86	
case3E:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 3'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case3F:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 3'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc ax
case40:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'AX'  
	mov byte[linha_de_comando + 6],10
	ret
;;inc cx
case41:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'CX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc dx
case42:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'DX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc bx	
case43:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'BX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc sp
case44:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'SP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc bp
case45:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'BP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc si	
case46:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'SI'  
	mov byte[linha_de_comando + 6],10
	ret 
;;inc di	
case47:
	mov cx, 7
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'DI'  
	mov byte[linha_de_comando + 6],10
	ret 

;;dec ax
case48:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'AX'  
	mov byte[linha_de_comando + 6],10
	ret
;;dec cx
case49:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'CX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec dx
case4A:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'DX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec bx	
case4B:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'BX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec sp
case4C:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'SP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec bp
case4D:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'BP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec si	
case4E:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'SI'  
	mov byte[linha_de_comando + 6],10
	ret 
;;dec di	
case4F:
	mov cx, 7
	mov word[linha_de_comando],'de'
	mov word[linha_de_comando + 2],'c '
	mov word[linha_de_comando + 4],'DI'  
	mov byte[linha_de_comando + 6],10
	ret

;;push ax
case50:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' A'  
	mov byte[linha_de_comando + 6],'X'
	mov byte[linha_de_comando + 7],10	
	ret
;;push cx
case51:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' C'  
	mov byte[linha_de_comando + 6],'X'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push dx
case52:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' D'  
	mov byte[linha_de_comando + 6],'X'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push bx	
case53:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' B'  
	mov byte[linha_de_comando + 6],'X'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push sp
case54:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' S'  
	mov byte[linha_de_comando + 6],'P'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push bp
case55:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' B'  
	mov byte[linha_de_comando + 6],'P'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push si	
case56:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' S'  
	mov byte[linha_de_comando + 6],'I'
	mov byte[linha_de_comando + 7],10	
	ret 
;;push di	
case57:
	mov cx, 8
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov word[linha_de_comando + 4],' D'  
	mov byte[linha_de_comando + 6],'I'
	mov byte[linha_de_comando + 7],10	
	ret
;;pop ax
case58:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'AX'  
	mov byte[linha_de_comando + 6],10
	ret
;;pop cx
case59:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'CX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop dx
case5A:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'DX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop bx	
case5B:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'BX'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop sp
case5C:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'SP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop bp
case5D:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'BP'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop si	
case5E:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'SI'  
	mov byte[linha_de_comando + 6],10
	ret 
;;pop di	
case5F:
	mov cx, 7
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'p '
	mov word[linha_de_comando + 4],'DI'  
	mov byte[linha_de_comando + 6],10
	ret	

;;pusha	
case60:
	mov cx, 6
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'
	mov byte[linha_de_comando + 4],'a'  
	mov byte[linha_de_comando + 5],10
	ret
;;popa
case61:
	mov cx, 5
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'pa'
	mov byte[linha_de_comando + 4],10
	ret	

;;; Funcao invalida para processador 80X86	
case62:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'2h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case63:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'3h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case64:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'4h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case65:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'5h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case66:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'6h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case67:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'7h'  
	mov byte[linha_de_comando + 6],10
	ret 


case68:
case69:



;;; Funcao invalida para processador 80X86	
case6A:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Ah'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case6B:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Bh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case6C:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Ch'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case6D:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Dh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case6E:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
case6F:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' 6'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 


case70:
case71:
case72:
case73:
case74:
case75:
case76:
case77:
case78:
case79:
case7A:
case7B:
case7C:
case7D:
case7E:
case7F:


case80:
case81:
case82:
case83:
case84:
case85:
case86:
case87:
case88:
case89:
case8A:
case8B:
case8C:
case8D:
case8E:
case8F:
	

case90:
;;xchg ax, cx
case91:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'CX'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, dx
case92:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'DX'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, bx	
case93:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'BX'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, sp
case94:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'SP'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, bp
case95:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'BP'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, si	
case96:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'SI'  
	mov byte[linha_de_comando + 14],10
	ret 
;;xchg ax, di	
case97:
	mov cx, 15
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov word[linha_de_comando + 4],' A'
	mov word[linha_de_comando + 8],'X,'
	mov word[linha_de_comando + 10],'  '		
	mov word[linha_de_comando + 12],'DI'  
	mov byte[linha_de_comando + 14],10
	ret 	
;;cbw 
case98:
	mov cx, 4
	mov word[linha_de_comando],'cb'
	mov byte[linha_de_comando + 2],'w'
	mov byte[linha_de_comando + 3],10
;;cwb 
case99:
	mov cx, 4
	mov word[linha_de_comando],'cw'
	mov byte[linha_de_comando + 2],'b'
	mov byte[linha_de_comando + 3],10


case9A:


;;wait 
case9B:
	mov cx, 5
	mov word[linha_de_comando],'wa'
	mov word[linha_de_comando + 2],'it'
	mov byte[linha_de_comando + 4],10	
;;pushf
case9C:
	mov cx, 6
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'	
	mov byte[linha_de_comando + 4],'f'
	mov byte[linha_de_comando + 5],10	
;;popf
case9D:
	mov cx, 5
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'pf'
	mov byte[linha_de_comando + 4],10
;;sahf
case9E:
	mov cx, 5
	mov word[linha_de_comando],'sa'
	mov word[linha_de_comando + 2],'hf'
	mov byte[linha_de_comando + 4],10
;;lahf
case9F:
	mov cx, 5
	mov word[linha_de_comando],'la'
	mov word[linha_de_comando + 2],'hf'
	mov byte[linha_de_comando + 4],10
	
caseA0:
caseA1:
caseA2:
caseA3:
	
	
;;; Funcao invalida para processador 80X86	
caseA4:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'4h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseA5:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'5h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseA6:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'6h'  
	mov byte[linha_de_comando + 6],10
	ret 

caseA7:
caseA8:
caseA9:

	
;;; Funcao invalida para processador 80X86	
caseAA:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Ah'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseAB:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Bh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseAC:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Ch'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseAD:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Dh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseAE:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseAF:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 

;;mov AL, XYh
caseB0:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;;mov CL, XYh
caseB1:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;;mov DL, XYh
caseB2:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;;mov BL, XYh
caseB3:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;; mov AH, XYh
caseB4:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AH'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret
;;mov CH, XYh
caseB5:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CH'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;;mov DH, XYh
caseB6:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DH'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;;mov BH, XYh
caseB7:
	mov cx, 12
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BH'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	

;;mov AX, XYZWh
caseB8:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
;;mov CX, XYZWh
caseB9:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
;; mov DX, XYZWh
caseBA:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret
;;mov BX, XYZWh
caseBB:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
	
;;mov SP, XYZWh
caseBC:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'SP'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
;;mov BP, XYZWh	
caseBD:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BP'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
;;mov SI, XYZWh	
caseBE:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'SI'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	
;;mov DI, XYZWh	
caseBF:
	mov cx,14 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DI'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10	


caseC0:
caseC1:
caseC2:
caseC3:
caseC4:
caseC5:

;;; Funcao invalida para processador 80X86	
caseC6:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' C'
	mov word[linha_de_comando + 4],'6h'  
	mov byte[linha_de_comando + 6],10
	ret 

caseC7:

;;; Funcao invalida para processador 80X86	
caseC8:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' C'
	mov word[linha_de_comando + 4],'8h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseC9:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' C'
	mov word[linha_de_comando + 4],'9h'  
	mov byte[linha_de_comando + 6],10
	ret 

caseCA:
caseCB:
caseCC:

;; 'int XYh', 10
caseCD:
	mov cx, 8
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'t '
	inc di
	call HexToAscii		; ax <- 'XY'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6],'h'
	mov byte[linha_de_comando + 7],10
	call VerificaInt
	ret
;;; Funcao invalida para processador 80X86	
caseCE:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' C'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseCF:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' C'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 

	
caseD0:
caseD1:
caseD2:
caseD3:

;;; Funcao invalida para processador 80X86	
caseD4:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'4h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseD5:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'5h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseD6:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'6h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseD7:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'7h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseD8:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'8h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseD9:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'9h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDA:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Ah'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDB:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Bh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDC:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Ch'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDD:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Dh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDE:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseDF:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' D'
	mov word[linha_de_comando + 4],'Fh'  
	mov byte[linha_de_comando + 6],10
	ret 


;;; Funcao invalida para processador 80X86	
caseE0:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' E'
	mov word[linha_de_comando + 4],'0h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseE1:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' E'
	mov word[linha_de_comando + 4],'1h'  
	mov byte[linha_de_comando + 6],10
	ret 

caseE2:	
caseE3:	
caseE4:	
caseE5:	
caseE6:	
caseE7:	
caseE8:	
caseE9:	
caseEA:	
caseEB:	
caseEC:	
caseED:	
caseEE:	
caseEF:	


;;; Funcao invalida para processador 80X86	
caseF0:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'0h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseF1:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'1h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseF2:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'2h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseF3:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'3h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseF4:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'4h'  
	mov byte[linha_de_comando + 6],10
	ret 
;;; Funcao invalida para processador 80X86	
caseF5:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'5h'  
	mov byte[linha_de_comando + 6],10
	ret

caseF6:	
caseF7:	

;;clc
caseF8:
	mov cx, 4
	mov word[linha_de_comando],'cl'
	mov byte[linha_de_comando + 2],'c'
	mov byte[linha_de_comando + 3],10	
;;stc
caseF9:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'c'
	mov byte[linha_de_comando + 3],10	
;;cli
caseFA:
	mov cx, 4
	mov word[linha_de_comando],'cl'
	mov byte[linha_de_comando + 2],'i'
	mov byte[linha_de_comando + 3],10	
;;sti
caseFB:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'i'
	mov byte[linha_de_comando + 3],10	
;;cld
caseFC:
	mov cx, 4
	mov word[linha_de_comando],'cl'
	mov byte[linha_de_comando + 2],'d'
	mov byte[linha_de_comando + 3],10	
;;std
caseFD:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'d'
	mov byte[linha_de_comando + 3],10	
	
;;; Funcao invalida para processador 80X86	
caseFE:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' F'
	mov word[linha_de_comando + 4],'Eh'  
	mov byte[linha_de_comando + 6],10
	ret 
	
caseFF:	
	


caseDefault:	


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; tabela das rotinas para cada instrucao ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;
	;; funcoes auxiliares ;;
	;;;;;;;;;;;;;;;;;;;;;;;;

	
;; Funcao de escrita da linha de comando no arquivo
;; Entrada: linha_de_comando definida;
;; 	    cx: numero de caracteres a serem escritos, incluindo o byte 13 (pula linha)
Imprime:	
	mov ah, 0x40
	mov bx, [handle_arq_out]
	;; cx contem o numero de caracteres a escrever
	mov dx, linha_de_comando
	int 0x21
	ret


;; Funcao de conversao de um byte para uma word que contem sua representacao em hexa (valores ascii)
;; Saida: AX <- valor em ascii do byte atual apontado por DI
HexToAscii:
	xor ax,ax		; ax <- 0x0000
	mov bl, byte[es:bin + di]
	mov bh, bl 		; bh <- copia do byte
	and bl, 00001111b	; bl <- apenas o nibble - significativo do byte

	;; AH <- valor em ascii da representacao em hexa do nibble MENOS significativo
	mov ah, bl
	cmp ah, 9
	ja MenosSignificativoMaiorNove
	;; 0 <= byte - significativo <= 9
	add ah, 0x30
	jmp MaisSignificativo
MenosSignificativoMaiorNove:
	;; byte - significativo >= A
	add ah, 0x37
MaisSignificativo:
	;; AL <- valor em ascii da representacao em hexa do nibble MAIS significativo
	mov al, bh 		; al <- byte original
	shr al, 4 		; al <- apenas o nibble + significativo do byte
	cmp al, 9
	ja MaisSignificativoMaiorNove
	;; 0 <= byte + significativo <= 9
	add al, 0x30
	ret
MaisSignificativoMaiorNove:	
	;; byte + significativo >= A
	add al, 0x37
	ret


;; Funcao que verifica se a interrupcao chamada foi de finalizacao da execucao.
;; Retorno: si=1 -> ultima instrucao
;; 	    si=0 -> continua nas instrucoes
VerificaInt:	
	;; dois casos:	1) int 20h
	;;		2) mov ah, 4Ch | int 21h

	;; caso 1
	cmp byte[es:bin + di], 20h
	jne ContinuaVerificaInt
	inc si			; si <- 1
	ret
ContinuaVerificaInt:	
	;; caso 2
	cmp byte[es:bin + di], 21h
	;; caso a interrupcao seja do tipo 21h, verifica se a inst. ant. foi 'mov ah, 4Ch'
	je ContinuaVerificaInt2
	;; caso contrario, retorna sem mexer no si
	ret
ContinuaVerificaInt2:
	cmp word[es:bin + di - 3], 0B44Ch
	jne FimVerificaInt
	inc si
FimVerificaInt:
	ret



	
	;;;;;;;;;;;;;;;;;;;;;;;;
	;; funcoes auxiliares ;;
	;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________ 



	

Fim:

	;; imprime mais uma nova linha no arquivo de saida
	mov cx, 1
	mov byte[linha_de_comando],10
	call Imprime
	
	;; recupera di
	pop di
	pop si
	
	;; fecha arquivo de saida
	mov bx, [handle_arq_out]
	mov ah, 0x3E
	int 0x21

	mov ah, 0x4C
	int 0x21


	
; _____________________________________________________________
	
;; segmento de dados
SEGMENT data

;; msg de erro
MsgErroAbreArquivo: db 'ERRO ao tentar abrir o arquivo. Verifique se o arquivo especificado esta no diretorio.',13,10,'$'

;; nome do arquivo de saida
arq_saida: db 'saida.asm',0x00

tam_arq_com: resb 2

handle_arq_out:	resb 2

;; espaco de memoria reservado para a 'montagem' da linha de comando, antes
;; desta ser escrita no arquivo
linha_de_comando: db 'org 100h',10,'section .text',10,'start:',10


;; Tabela de apontadores para o codigo
Table:
	dw case00
	dw case01
	dw case02
	dw case03
	dw case04
	dw case05
	dw case06
	dw case07
	dw case08
	dw case09
	dw case0A
	dw case0B
	dw case0C
	dw case0D
	dw case0E
	dw case0F
	dw case10
	dw case11
	dw case12
	dw case13
	dw case14
	dw case15
	dw case16
	dw case17
	dw case18
	dw case19
	dw case1A
	dw case1B
	dw case1C
	dw case1D
	dw case1E
	dw case1F
	dw case20
	dw case21
	dw case22
	dw case23
	dw case24
	dw case25
	dw case26
	dw case27
	dw case28
	dw case29
	dw case2A
	dw case2B
	dw case2C
	dw case2D
	dw case2E
	dw case2F
	dw case30
	dw case31
	dw case32
	dw case33
	dw case34
	dw case35
	dw case36
	dw case37
	dw case38
	dw case39
	dw case3A
	dw case3B
	dw case3C
	dw case3D
	dw case3E
	dw case3F
	dw case40
	dw case41
	dw case42
	dw case43
	dw case44
	dw case45
	dw case46
	dw case47
	dw case48
	dw case49
	dw case4A
	dw case4B
	dw case4C
	dw case4D
	dw case4E
	dw case4F
	dw case50
	dw case51
	dw case52
	dw case53
	dw case54
	dw case55
	dw case56
	dw case57
	dw case58
	dw case59
	dw case5A
	dw case5B
	dw case5C
	dw case5D
	dw case5E
	dw case5F
	dw case60
	dw case61
	dw case62
	dw case63
	dw case64
	dw case65
	dw case66
	dw case67
	dw case68
	dw case69
	dw caseDefault
	dw caseDefault
	dw caseDefault
	dw caseDefault
	dw caseDefault
	dw caseDefault
	dw case70
	dw case71
	dw case72
	dw case73
	dw case74
	dw case75
	dw case76
	dw case77
	dw case78
	dw case79
	dw case7A
	dw case7B
	dw case7C
	dw case7D
	dw case7E
	dw case7F
	dw case80
	dw case81
	dw case82
	dw case83
	dw case84
	dw case85
	dw case86
	dw case87
	dw case88
	dw case89
	dw case8A
	dw case8B
	dw case8C
	dw case8D
	dw case8E
	dw case8F
	dw case90
	dw case91
	dw case92
	dw case93
	dw case94
	dw case95
	dw case96
	dw case97
	dw case98
	dw case99
	dw case9A
	dw case9B
	dw case9C
	dw case9D
	dw case9E
	dw case9F
	dw caseA0
	dw caseA1
	dw caseA2
	dw caseA3
	dw caseA4
	dw caseA5
	dw caseA6
	dw caseA7
	dw caseA8
	dw caseA9
	dw caseAA
	dw caseAB
	dw caseAC
	dw caseAD
	dw caseAE
	dw caseAF
	dw caseB0
	dw caseB1
	dw caseB2
	dw caseB3
	dw caseB4
	dw caseB5
	dw caseB6
	dw caseB7
	dw caseB8
	dw caseB9
	dw caseBA
	dw caseBB
	dw caseBC
	dw caseBD
	dw caseBE
	dw caseBF
	dw caseC0
	dw caseC1
	dw caseC2
	dw caseC3
	dw caseC4
	dw caseC5
	dw caseC6
	dw caseC7
	dw caseC8
	dw caseC9
	dw caseCA
	dw caseCB
	dw caseCC
	dw caseCD
	dw caseCE
	dw caseCF
	dw caseD0
	dw caseD1
	dw caseD2
	dw caseD3
	dw caseD4
	dw caseD5
	dw caseD6
	dw caseD7
	dw caseD8
	dw caseD9
	dw caseDA
	dw caseDB
	dw caseDC
	dw caseDD
	dw caseDE
	dw caseDF
	dw caseE0
	dw caseE1
	dw caseE2
	dw caseE3
	dw caseE4
	dw caseE5
	dw caseE6
	dw caseE7
	dw caseE8
	dw caseE9
	dw caseEA
	dw caseEB
	dw caseEC
	dw caseED
	dw caseEE
	dw caseEF
	dw caseF0
	dw caseF1
	dw caseF2
	dw caseF3
	dw caseF4
	dw caseF5
	dw caseF6
	dw caseF7
	dw caseF8
	dw caseF9
	dw caseFA
	dw caseFB
	dw caseFC
	dw caseFD
	dw caseFE
	dw caseFF

	

;; Vetor de registradores
;; Tamanho de cada elemento: 2 bytes (2 caracteres)
;; Indice: vai de 0h a Fh
;; Exemplos...
;; word[vetor_registradores + 2*0h] = 'AL'
;; word[vetor_registradores + 2*8h] = 'AX'
;; word[vetor_registradores + 2*Fh] = 'DI'
;; 
;; 			|----- w=0 -----||----- w=1 -----|
vetor_registradores: db 'ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI'
;; 			|0-1-2-3-4-5-6-7||8-9-A-B-C-D-E-F|

	
;; Vetor das instrucoes de shift e rotacoes
;; Tamanho de cada elemento: 3 bytes (3 caracteres)
;; Indice: vai de 0h a 7h
;; Exemplos...
;; 3<bytes>[vetor_TTT + 3*0h] = 'rol'
;; 3<bytes>[vetor_TTT + 3*7h] = 'sar'
;;
vetor_TTT: db 'rolrorrclrcrshlshr---sar'
;;	      |-0--1--2--3--4--5--6--7-|
	
; _____________________________________________________________	
	
	
;; este segmento (ES) eh para guardar o arquivo executavel .COM inteiro na memoria
SEGMENT data2
bin:	resb 0xFFF0	; ~64K (ao colocar 0xFFFF, o tlink diz que o segmento excede 64K)


	
; _____________________________________________________________
	
SEGMENT stack stack
	resb 0xFF	;; 256 bytes
stacktop:
