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
	mov bx, ax 		; bx <- handle do arquivo de saida
	mov [handle_arq_out],bx	; salva o handle do arquivo de saida na memoria

	jmp While
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; abertura do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
; _____________________________________________________________

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; processamento dos dados ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;; Para percorrer todos os bytes do arquivo executavel, o registrador DI sera
	;; usado como indice de acesso (facilitando o enderecamento com o segmento ES)

	push di			; salva di na pilha
	xor di, di		; di <- 0x0000

While:	
	;; Interpretacao dos bytes do arquivo binario:
	;; Usaremos uma tabela com enderecos de trechos do codigo (do segmento CS).
	;; Para isso, a indexacao da tabela eh feita diretamente com o byte do arquivo .COM

	;; BX sera usado como o indice para a tabela
	xor bx, bx		; bx <- 0x0000
	mov bl, byte[bin + di]	; bl <- byte do arquivo executavel
	call [Table + 2*bx]	; chamada da rotina para a instrucao especifica
	call Imprime		; escreve a linha de comando no arquivo de saida

	;; caso o di ja tenha percorrido todo o arquivo .COM, termina a execucao
	inc di
	cmp di, [tam_arq_com]
	je Fim
	;; caso contrario, executa novamente para o proximo comando
	jmp While

	
;; Rotina de escrita da linha de comando no arquivo
Imprime:	
	mov ah, 0x40
	mov bx, [handle_arq_out]
	;; cx contem o numero de caracteres a escrever
	mov dx, linha_de_comando
	int 0x21


;; Saida: AX <- valor em ascii do byte atual apontado pelo DI
HexToAscii:
	xor ax,ax		; ax <- 0x0000
	mov bl, byte[bin + di]
	mov bh, bl
	and bl, 00001111b	; bl <- nibble - significativo do byte
	and bh, 11110000b	; bh <- nibble + significativo do byte

	;; AH <- ascii do nibble MENOS significativo


	


	;; AL <- ascii do nibble MAIS significativo



	
	
	;; Rotinas de "montagem" da linha de comando
	;; Saida: linha_de_comando definida
	;; 	  cx <- numero de caracteres da linha de comando (incluindo 0x13)






;;; Funcao nao valida para processador 80X86
case0F:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86
case26:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'26'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case27:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'27'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case2E:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'2E'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case2F:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'2F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case36:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'36'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case37:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'37'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case3E:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'3E'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case3F:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'3F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case62:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'62'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case63:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'63'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case64:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'64'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case65:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'65'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case66:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'66'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
case67:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'67'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseA4:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'A4'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseA5:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'A5'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseA6:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'A6'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAA:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AA'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAB:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AB'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAC:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AC'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAD:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AD'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAE:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AE'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseAF:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'AF'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseC6:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'C6'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseC8:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'C8'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseC9:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'C9'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
	

;; 'int XXh',0x13	
caseCD:
	mov cx, 8
	mov word[linha_de_comando],'in'
	mov word[linha_de_comando + 2],'t '
	inc di
	call HexToAscii		; ax <- 'XX'
	mov word[linha_de_comando + 4], ax
	mov word[linha_de_comando + 6],'h',0x13
	ret
	
;;; Funcao nao valida para processador 80X86	
caseCE:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'CE'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseCF:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'CF'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD4:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D4'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD5:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D5'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD6:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D6'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD7:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D7'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD8:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D8'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseD9:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'D9'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDA:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DA'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDB:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DB'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDC:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DC'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDD:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DD'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDE:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DE'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseDF:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'DF'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseE0:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseE1:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'E1'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF0:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF1:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF2:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF3:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'0F'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF4:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'F4'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseF5:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'F5'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
;;; Funcao nao valida para processador 80X86	
caseFE:
    mov cx, 8
    mov word[linha_de_comando],'db'
    mov word[linha_de_comando + 2],'  '
    mov word[linha_de_comando + 4],'FE'
    mov word[linha_de_comando + 6],'h', 0x13
    ret 
	
	

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; processamento dos dados ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________ 
	

Fim:

	;; recupera di
	pop di
	
	;; fecha arquivo de saida
	mov ah, 0x3E
	;; bx continua contendo o handle do arq de saida
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
linha_de_comando: resb 50


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
