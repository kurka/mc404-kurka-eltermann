SEGMENT code
..start:

	;; inicializa segmento de pilha
	mov ax, stack
	mov ss, ax
	mov sp, stacktop

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificação da validade do argumento passado ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	mov bl, [ds:0x80]	;; bl contem o numero de caracteres do nome do arquivo de entrada
	cmp bl, 10			;; ' imgXX.bmp' == 10 caracteres
	je VerificaFormato	;; se for = a 10, verifica o formato do arquivo
	;; caso contrário, inicializa o segmento de dados apenas para mostrar msg de erro
ErroFormato:
	mov ax, data
	mov ds, ax
	mov ah, 9
	mov dx, MsgErroFormato
	int 0x21			;; exibe msg de erro
	jmp Fim				;; termina a execução do programa
	
VerificaFormato:
	;; verificação caractere por caractere (byte a byte ou word a word)
	mov bx, word[ds:0x82]	;; 'im'
	cmp bx, 'im'
	jne ErroFormato
	mov bl, byte[ds:0x84]	;; 'g'
	cmp bl, 'g'
	jne ErroFormato
	mov bx, word[ds:0x85]	;; XX (dois dígitos numéricos)
	call VerificaDigitos	;; 0 -> OK | 1 -> errado
	cmp bh, 1
	je ErroFormato
	mov bx, word[ds:0x87]	;; '.b'
	cmp bx, '.b'
	jne ErroFormato
	mov bx, word[ds:0x89]	;; 'mp'
	cmp bx, 'mp'
	jne ErroFormato
	;; se a execução chegar até aqui, o formato está OK!
	jmp AbreArquivo
	
;; função de verificação dos dígitos numéricos
;; entrada: bx
;; saida: se bh e bx forem dígitos numéricos (entre 0 e 9), bh <- 0
;;;;;;;;;;;;; caso contrario, bh <- 1
VerificaDigitos:
	;; (30<= bh <= 39) && (30<= bl <= 39)
	cmp bh, 0x30
	jl ErroVerificaDigitos
	cmp bh, 0x39
	jg ErroVerificaDigitos
	cmp bl, 0x30
	jl ErroVerificaDigitos
	cmp bl, 0x39
	jg ErroVerificaDigitos
	;; se chegar até aqui, está OK!
	mov bh, 0
	jmp FimVerificaDigitos
	
	ErroVerificaDigitos:
		mov bh, 1
		jmp FimVerificaDigitos

	FimVerificaDigitos:
		ret
	

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificação da validade do argumento passado ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
AbreArquivo:	
	;; abertura do arquivo
	mov ah, 0x3D			;; serviço do DOS de abertura de arquivo
	mov al, 0			;; modo de abertura: read-only
	mov bh, 0x00
	mov bl, [ds:0x80]		;; n de caracteres do argumento
	mov byte[ds:0x82+bx-1], 0x00	;; nome do arquivo deve terminar com o byte 0x00 (ASCIIZ)
	mov dx, 0x82			;; offset para o primeiro caractere do nome do arquivo
	int 0x21
	mov bx, ax			;; bx <- handle do arquivo aberto
	
	;; agora o valor antigo de ds já não é importante, pois já foi utilizado o argumento passado ao programa.
	;; portanto, o segmento de dados é inicializado definitivamente.
	mov ax, data
	mov ds, ax
	
	;; verificar a flag Carry
	jc ErroAbreArquivo
	;; se chegar até aqui, o arquivo abriu normalmente e AX contem o handle para o arquivo de entrada
	mov [handle_arq_in], bx		;; o handle do arquivo eh salvo na memoria
	jmp VerificaImagem
	
ErroAbreArquivo:
	mov ah, 9
	mov dx, MsgErroAbreArquivo
	int 0x21			;; exibe msg de erro
	jmp Fim				;; termina a execução do programa
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificacao e leitura do arquivo para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
VerificaImagem:
	;; leitura dos dois primeiros bytes do arquivo
	mov ah, 0x3F		; servico de leitura
	mov bx, [handle_arq_in]
	mov cx, 2		; n de bytes a serem lidos
	mov dx, tipo_arq	; ds:dx aponta para onde os bytes serao lidos
	int 0x21

	;; verificacao do tipo do arquivo
	mov ax, [tipo_arq]
	cmp ax, 'BM'		; caso os caracteres lidos dos 2 primeiros bytes do arquivo
	je CarregaImagem	; sejam 'BM', carrega o resto do arquivo na memoria
	;; caso contrario, o arquivo nao eh do tipo bmp (mesmo com a extensao no nome)
	;; fecha arquvo, imprime msg de erro e finaliza execucao
	mov ah, 0x3E
	;; como a leitura n afeta bx, este continua tendo o valor do handle do arquivo
	int 0x21
	mov ah, 9
	mov dx, MsgErroArquivo
	int 0x21
	jmp Fim
	

CarregaImagem:	
	;; leitura do tamanho do arquivo
	;; assumiremos que o arquivo tem no maximo 64K, entao os 2 primeiros bytes que representam
	;; o tamanho estarao necessariamente zerados: 0000 XXXXh
	;; portanto, moveremos o apontador interno do arquivo de duas unidades (desconsideraremos os bytes zerados)
	mov ah, 0x42		; servico do DOS para mover o file pointer
	;; bx continua contendo o handle para o arquivo
	mov cx, 0
	mov dx, 2		; avanco de 2 bytes
	mov al, 1		; move a partir da posicao corrente
	int 0x21

	;; leitura dos dois bytes do tamanho
	mov ah, 0x3F
	;; bx continua contendo o handle para o arquivo
	mov cx, 2
	mov dx, tamanho_arq
	int 0x21

	;; para a leitura do arquivo inteiro, primeiramente, setaremos o file pointer para
	;; o inicio (como se tivessemos acabado de abri-lo)
	mov ah, 0x42
	;; bx continua contendo o handle para o arquivo
	mov cx, 0		
	mov dx, 0		; move 0 bytes
	mov al, 0		; a partir do inicio do arquivo
	int 0x21

	;; **PROBLEMA**
	;; para a leitura, colocaremos o valor de ES temporariamente em DS
	push ds			; guarda ds na pilha
	mov ax, es
	mov ds, ax
	mov dx, img		; DS:DX <- "ES:img"
	;; bx continua contendo o handle para o arquivo
	mov cx, 10
	int 0x21		; arquivo eh salvo INTEIRO na memoria no segmento ES
	;; **PROBLEMA**
	
	;; recupera ds
	pop ds

	;; fecha o arquivo de entrada
	mov ah, 0x3E
	;; bx continua contendo o handle para o arquivo
	int 0x21
	jmp Next
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificacao e leitura do arquivo para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________ 
	
Next:	

Fim:
	mov ah, 0x4C
	int 0x21

	
;; segmento de dados
SEGMENT data

;; nomes dos arquivos de entrada e saida
arq_out: db 'saida.bmp',0x00

;; apontador (handle) para os arquivos de entrada e saida
handle_arq_in: resb 2
handle_arq_out: resb 2

;; msg de erro
MsgErroFormato: db 'ERRO: Verifique se o nome do arquivo esta no formato imgXX.bmp',13,10,'$'
MsgErroAbreArquivo: db 'ERRO ao tentar abrir o arquivo. Verifique se o arquivo especificado esta no diretorio.',13,10,'$'
MsgErroArquivo:	db 'ERRO: O arquivo nao eh do tipo BMP especificado.',13,10,'$'
	
;; variaveis usadas na leitura do arquivo
tipo_arq: resb 2
tamanho_arq: resb 2
	

;; este segmento (ES) eh para guardar o arquivo inteiro na memoria.
SEGMENT data2
img:	resb 0xFFF0	; ~64K (ao colocar 0xFFFF, o tlink diz que o segmento excede 64K)
	

	
SEGMENT stack stack
	resb 0xFF	;; 256
stacktop:
