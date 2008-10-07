SEGMENT code
..start:

	;; inicializa segmento de pilha
	mov ax, stack
	mov ss, ax
	mov sp, stacktop

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificação da validade do argumento passado ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
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
	

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificação da validade do argumento passado ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
AbreArquivo:	
	mov ah, 0x3D		;; serviço do DOS de abertura de arquivo
	mov al, 0			;; modo de abertura: read-only
	mov bh, 0x00
	mov bl, [ds:0x80]	;; n de caracteres do argumento
	mov byte[ds:0x82+bx-1], 0x00	;; nome do arquivo deve terminar com o byte 0x00 (ASCIIZ)
	mov dx, 0x82		;; offset para o primeiro caractere do nome do arquivo
	int 0x21
	
	;; agora o valor antigo de ds já não é importante, pois já foi utilizado o argumento passado ao programa.
	;; portanto, o segmento de dados é inicializado definitivamente.
	mov ax, data
	mov ds, ax
	
	;; verificar a flag Carry
	pushf
	pop bx
	and bx, 0x0001
	cmp bx, 1				;; CF=0 -> OK / CF=1 -> erro na abertura do arquivo
	je ErroAbreArquivo
	;; se chegar até aqui, o arquivo abriu normalmente e AX contem o handle para o arquivo de entrada
	mov [ap_arq_in], ax		;; o handle do arquivo é salvo na memória
	jmp Next
	
ErroAbreArquivo:
	mov ah, 9
	mov dx, MsgErroAbreArquivo
	int 0x21			;; exibe msg de erro
	jmp Fim				;; termina a execução do programa
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de entrada ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________

Next:
	
Fim:
	mov ah, 0x4C
	int 0x21
	
	
SEGMENT data

;; nomes dos arquivos de entrada e saida
arq_out: db 'saida.bmp',0x00

;; apontador (handle) para os arquivos de entrada e saida
ap_arq_in: resb 2
ap_arq_out: resb 2

;; msg de erro
MsgErroFormato: db 'ERRO: Verifique se o nome do arquivo esta no formato imgXX.bmp',13,10,'$'
MsgErroAbreArquivo: db 'ERRO ao tentar abrir o arquivo. Verifique se o arquivo especificado esta no diretorio.',13,10,'$'

;SEGMENT img


SEGMENT stack stack
	resb 0xFF	;; 256
stacktop:
