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
	jmp Next
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; leitura do arquivo executavel para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________ 


Next:	
	
	;; Criacao do arquivo de saida (que contera o codigo do programa)
	mov ah, 0x3C
	xor cx, cx 		; cx <- 0x0000
	mov dx, arq_saida	; dx aponta para o nome do arquivo
	int 0x21
	mov bx, ax 		; bx <- handle do arquivo de saida


	;;/* AREA DE TESTES!!! ;;

	;; Teste da leitura: copiar o arquivo binario exatamente como ele eh, para o arquivo de saida
	;; e comparar os dois (diff)

	;; bx continua contendo o handle do arq de saida
	mov cx, [tam_arq_com]
	push ds
	mov ax, es
	mov ds, ax
	mov dx, bin 		; DS:DX <- "ES:bin"
	mov ah, 0x40
	int 0x21

	pop ds

	jmp Fim
	
	;; fecha arquivo de saida
	mov ah, 0x3E
	;; bx continua contendo o handle do arq de saida
	int 0x21
	

	;; AREA DE TESTES!!! */;;	

	
	

Fim:
	mov ah, 0x4C
	int 0x21


	
; _____________________________________________________________
	
;; segmento de dados
SEGMENT data

;; msg de erro
MsgErroAbreArquivo: db 'ERRO ao tentar abrir o arquivo. Verifique se o arquivo especificado esta no diretorio.',13,10,'$'

;; nome do arquivo de saida
arq_saida: db 'codigo.asm',0x00

tam_arq_com: resb 2



;; espaco de memoria reservado para a 'montagem' da linha de comando, antes
;; desta ser escrita no arquivo
linha_de_comando: resb 50


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
