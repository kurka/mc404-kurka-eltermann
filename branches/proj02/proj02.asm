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


;add  reg8/mem8, reg8 	
case00:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;;add  reg16/mem16,reg16
case01:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;add  reg8,reg8/mem8
case02:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;add   reg16,reg16/mem16 
case03:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
;add AL, XYh
case04:
	mov cx, 12
	mov word[linha_de_comando], 'ad'
	mov word[linha_de_comando + 2], 'd '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret
;add AX, XYZW
case05:
	mov cx,14 
	mov word[linha_de_comando], 'ad'
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
	ret
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
;or   reg8/mem8,reg8
case08:
	mov word[linha_de_comando],'or'
	mov byte[linha_de_comando + 2],' '
	inc di
	mov bx, 3
	call RMDestino8
	ret		
;or   reg16/mem16,reg16	
case09:
	mov word[linha_de_comando],'or'
	mov byte[linha_de_comando + 2],' '
	inc di
	mov bx, 3
	call RMDestino16
	ret	
;or   reg8,reg8/mem8
case0A:
	mov word[linha_de_comando],'or'
	mov byte[linha_de_comando + 2],' '
	inc di
	mov bx, 3
	call RMFonte8
	ret			
;or   reg16,reg16/mem16
case0B:
	mov word[linha_de_comando],'or'
	mov byte[linha_de_comando + 2],' '
	inc di
	mov bx, 3
	call RMFonte16
	ret		
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
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret
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
;adc  reg8/mem8,reg8
case10:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'c '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;adc   reg16/mem16,reg16	
case11:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'c '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;adc  reg8,reg8/mem8
case12:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'c '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;adc   reg16,reg16/mem16
case13:
	mov word[linha_de_comando],'ad'
	mov word[linha_de_comando + 2],'c '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
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
	mov word[linha_de_comando + 10], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret
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
;sbb  reg8/mem8,reg8
case18:
	mov word[linha_de_comando],'sb'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;sbb   reg16/mem16,reg16	
case19:
	mov word[linha_de_comando],'sb'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;sbb  reg8,reg8/mem8
case1A:
	mov word[linha_de_comando],'sb'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;sbb   reg16,reg16/mem16
case1B:
	mov word[linha_de_comando],'sb'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
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
	ret
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
;and  reg8/mem8,reg8
case20:
	mov word[linha_de_comando],'an'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;and   reg16/mem16,reg16	
case21:
	mov word[linha_de_comando],'an'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;and  reg8,reg8/mem8
case22:
	mov word[linha_de_comando],'an'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;and   reg16,reg16/mem16
case23:
	mov word[linha_de_comando],'an'
	mov word[linha_de_comando + 2],'d '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
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
	ret
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
;sub  reg8/mem8,reg8
case28:
	mov word[linha_de_comando],'su'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;sub   reg16/mem16,reg16	
case29:
	mov word[linha_de_comando],'su'
	mov word[linha_de_comando + 2],'b '
	mov bx, 4
	call RMDestino16
	ret	
;sub  reg8,reg8/mem8
case2A:
	mov word[linha_de_comando],'su'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;sub   reg16,reg16/mem16
case2B:	
	mov word[linha_de_comando],'su'
	mov word[linha_de_comando + 2],'b '
	inc di
	mov bx, 4
	call RMFonte16
	ret
;sub   AL, XYh
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
	ret
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
;xor  reg8/mem8,reg8	
case30:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;xor   reg16/mem16,reg16
case31:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;xor  reg8,reg8/mem8
case32:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;xor  reg16,reg16/mem16
case33:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
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
	ret
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
;xor  reg8/mem8,reg8
case38:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMDestino8
	ret		
;xor  reg16/mem16,reg16	
case39:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMDestino16
	ret	
;xor  reg8,reg8/mem8
case3A:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMFonte8
	ret			
;xor  reg16,reg16/mem16
case3B:
	mov word[linha_de_comando],'xo'
	mov word[linha_de_comando + 2],'r '
	inc di
	mov bx, 4
	call RMFonte16
	ret		
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
	ret
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
;push XYZWh
case68:
	mov cx,12
	mov word[linha_de_comando], 'pu'
	mov word[linha_de_comando + 2], 'sh'
	mov word[linha_de_comando + 4], '  '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret

;;PROBLEMATICO! (comparar com tabela pra ver se nao tem nada de errado!)
;;imul XYZWh
case69:
	mov cx,12 
	mov word[linha_de_comando], 'im'
	mov word[linha_de_comando + 2], 'ul'
	mov word[linha_de_comando + 4], '  '
	inc di
	inc di		;ignora o segundo byte e le os outros
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret
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
;;jo 0XYh
case70:
	mov cx, 8
	mov word[linha_de_comando], 'jo'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret	
;;jno 0XYh
case71:
	mov cx, 9
	mov word[linha_de_comando], 'jn'
	mov word[linha_de_comando + 2], 'o '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jc 0XYh
case72:
	mov cx, 8
	mov word[linha_de_comando], 'jc'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;jnc 0XYh
case73:
	mov cx, 9
	mov word[linha_de_comando], 'jn'
	mov word[linha_de_comando + 2], 'c '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;je 0XYh
case74:
	mov cx, 8
	mov word[linha_de_comando], 'je'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;jne 0XYh
case75:
	mov cx, 9
	mov word[linha_de_comando], 'jn'
	mov word[linha_de_comando + 2], 'e '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jbe 0XYh
case76:
	mov cx, 9
	mov word[linha_de_comando], 'jb'
	mov word[linha_de_comando + 2], 'e '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;ja 0XYh
case77:
	mov cx, 8
	mov word[linha_de_comando], 'ja'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;js 0XYh
case78:
	mov cx, 8
	mov word[linha_de_comando], 'js'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;jns 0XYh
case79:
	mov cx, 9
	mov word[linha_de_comando], 'jn'
	mov word[linha_de_comando + 2], 's '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jp  0XYh
case7A:
	mov cx, 8
	mov word[linha_de_comando], 'jp'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;jnp 0XYh
case7B:
	mov cx, 9
	mov word[linha_de_comando], 'jn'
	mov word[linha_de_comando + 2], 'p '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jl 0XYh
case7C:	
	mov cx, 8
	mov word[linha_de_comando], 'jl'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret
;;jge 0XYh
case7D:
	mov cx, 9
	mov word[linha_de_comando], 'jg'
	mov word[linha_de_comando + 2], 'e '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jle 0XYh
case7E:
	mov cx, 9
	mov word[linha_de_comando], 'jl'
	mov word[linha_de_comando + 2], 'e '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 4], '0'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7], 'h'
	mov byte[linha_de_comando + 8], 10
	ret
;;jg 0XYh
case7F:
	mov cx, 8
	mov word[linha_de_comando], 'jg'
	mov byte[linha_de_comando + 2], ' '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 3], '0'
	mov word[linha_de_comando + 4], ax
	mov byte[linha_de_comando + 6], 'h'
	mov byte[linha_de_comando + 7], 10
	ret

case80:
case81:
case82:
case83:
;; test reg8/mem8,reg8
case84:
	mov word[linha_de_comando],'te'
	mov word[linha_de_comando + 2],'st'
	mov byte[linha_de_comando + 4], ' '
	inc di
	mov bx,5
	call RMDestino8
	ret
;; test reg16/mem16,reg16
case85:
	mov word[linha_de_comando],'te'
	mov word[linha_de_comando + 2],'st'
	mov byte[linha_de_comando + 4], ' '
	inc di
	mov bx, 5
	call RMDestino16
	ret
;xchg reg8,reg8/mem8
case86:
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov byte[linha_de_comando + 4], ' '
	inc di
	mov bx,5
	call RMFonte8
	ret
;xchg reg16,reg16/mem16
case87:
	mov word[linha_de_comando],'xc'
	mov word[linha_de_comando + 2],'hg'
	mov byte[linha_de_comando + 4], ' '
	inc di
	mov bx, 5
	call RMFonte16
	ret	
;mov  reg8/mem8,reg8
case88:
	mov word[linha_de_comando],'mo'
	mov word[linha_de_comando + 2],'v '
	inc di
	mov bx, 4
	call RMDestino8
	ret	
;; mov reg16/mem16,reg16	
case89:
	mov word[linha_de_comando],'mo'
	mov word[linha_de_comando + 2],'v '
	inc di
	mov bx, 4
	call RMDestino16
	ret
;mov  reg8,reg8/mem8
case8A:
	mov word[linha_de_comando],'mo'
	mov word[linha_de_comando + 2],'v '
	inc di
	mov bx, 4
	call RMFonte8
	ret		
;mov   reg16,reg16/mem16
case8B:
	mov word[linha_de_comando],'mo'
	mov word[linha_de_comando + 2],'v '
	inc di
	mov bx, 4
	call RMFonte16
	ret	
case8C:
;lea   reg16,mem16
	
	;; REVISAR!!! ;;
case8D:
	mov word[linha_de_comando],'le'
	mov word[linha_de_comando + 2],'a '
	inc di
	mov bx, 4
	call RMFonte16
	ret	
	;; REVISAR!!! ;;

case8E:
;;pop XYZWh
case8F:
	mov cx,12
	mov word[linha_de_comando], 'po'
	mov word[linha_de_comando + 2], 'p '
	mov word[linha_de_comando + 4], '  '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret
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
	ret
;;cwb 
case99:
	mov cx, 4
	mov word[linha_de_comando],'cw'
	mov byte[linha_de_comando + 2],'b'
	mov byte[linha_de_comando + 3],10
	ret
	
	;; REVISAR!!! ;;
;call [XYZW:KLMN]
case9A:
	mov cx, 18
	mov word[linha_de_comando], 'ca'
	mov word[linha_de_comando + 2], 'll'
	mov word[linha_de_comando + 4], ' ['
	inc di
	call HexToAscii
	mov word[linha_de_comando + 14], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 12], ax
	mov word[linha_de_comando + 10], 'h:'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax	
	mov byte[linha_de_comando + 16], 'h'
	mov byte[linha_de_comando + 17], 10
	ret
	;; REVISAR!!! ;;

;;wait 
case9B:
	mov cx, 5
	mov word[linha_de_comando],'wa'
	mov word[linha_de_comando + 2],'it'
	mov byte[linha_de_comando + 4],10
	ret
;;pushf
case9C:
	mov cx, 6
	mov word[linha_de_comando],'pu'
	mov word[linha_de_comando + 2],'sh'	
	mov byte[linha_de_comando + 4],'f'
	mov byte[linha_de_comando + 5],10
	ret
;;popf
case9D:
	mov cx, 5
	mov word[linha_de_comando],'po'
	mov word[linha_de_comando + 2],'pf'
	mov byte[linha_de_comando + 4],10
	ret
;;sahf
case9E:
	mov cx, 5
	mov word[linha_de_comando],'sa'
	mov word[linha_de_comando + 2],'hf'
	mov byte[linha_de_comando + 4],10
	ret
;;lahf
case9F:
	mov cx, 5
	mov word[linha_de_comando],'la'
	mov word[linha_de_comando + 2],'hf'
	mov byte[linha_de_comando + 4],10
	ret
;;mov AL, [0XYh] 
caseA0:
	mov cx, 15
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	mov word[linha_de_comando + 8], '[0'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov word[linha_de_comando + 12], 'h]'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov AX, [0XYZWh] 
caseA1:
	mov cx, 17
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	mov word[linha_de_comando + 8], '[0'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 12], ax
	call HexToAscii
	mov word[linha_de_comando + 10], ax	
	mov word[linha_de_comando + 14], 'h]'
	mov byte[linha_de_comando + 16], 10
	ret	
;;mov [0XYh], AL 
caseA2:
	mov cx, 15
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], '[0'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax
	mov word[linha_de_comando + 8], 'h]'	
	mov word[linha_de_comando + 10], ', '
	mov word[linha_de_comando + 12], 'AL'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov [0XYZWh], AX
caseA3:
	mov cx, 17
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], '[0'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	call HexToAscii
	mov word[linha_de_comando + 6], ax	
	mov word[linha_de_comando + 10], 'h]'	
	mov word[linha_de_comando + 12], ', '
	mov word[linha_de_comando + 14], 'AX'
	mov byte[linha_de_comando + 16], 10
	ret	
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
;;; Funcao invalida para processador 80X86	
caseA7:
	mov cx, 7
	mov word[linha_de_comando],'db'
	mov word[linha_de_comando + 2],' A'
	mov word[linha_de_comando + 4],'7h'  
	mov byte[linha_de_comando + 6],10
	ret
;test AX, 0XYh
caseA8:
	mov cx, 14
	mov word[linha_de_comando], 'te'
	mov word[linha_de_comando + 2], 'st'
	mov byte[linha_de_comando + 4], ' '
	mov word[linha_de_comando + 5], 'AL'
	mov word[linha_de_comando + 7], ', '
	inc di
	call HexToAscii
	mov byte[linha_de_comando + 9], '0'
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret
;test AX, 0XYZWh
caseA9:
	mov cx, 16
	mov word[linha_de_comando], 'te'
	mov word[linha_de_comando + 2], 'st'
	mov byte[linha_de_comando + 4], ' '
	mov word[linha_de_comando + 5], 'AX'
	mov word[linha_de_comando + 7], ', '
	mov byte[linha_de_comando + 9], 'h'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 12], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax	
	mov byte[linha_de_comando + 14], 'h'
	mov byte[linha_de_comando + 15], 10
	ret
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
	
;;mov AL, 0XYh
caseB0:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;;mov CL, 0XYh
caseB1:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CL'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;;mov DL, 0XYh
caseB2:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DL'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;;mov BL, 0XYh
caseB3:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BL'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;; mov AH, 0XYh
caseB4:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AH'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret
;;mov CH, 0XYh
caseB5:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CH'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;;mov DH, 0XYh
caseB6:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DH'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	
;;mov BH, 0XYh
caseB7:
	mov cx, 13
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BH'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 11], 'h'
	mov byte[linha_de_comando + 12], 10
	ret	

;;mov AX, 0XYZWh
caseB8:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov CX, 0XYZWh
caseB9:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'CX'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;; mov DX, 0XYZWh
caseBA:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DX'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov BX, 0XYZWh
caseBB:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BX'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10	
	ret
;;mov SP, 0XYZWh
caseBC:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'SP'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov BP, 0XYZWh	
caseBD:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'BP'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov SI, 0XYZWh	
caseBE:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'SI'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10
	ret
;;mov DI, 0XYZWh	
caseBF:
	mov cx,15 
	mov word[linha_de_comando], 'mo'
	mov word[linha_de_comando + 2], 'v '
	mov word[linha_de_comando + 4], 'DI'
	mov word[linha_de_comando + 6], ', '
	mov byte[linha_de_comando + 8], '0'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 11], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 9], ax
	mov byte[linha_de_comando + 13], 'h'
	mov byte[linha_de_comando + 14], 10	
	ret

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

;; int 0XYh
caseCD:
	mov cx, 9
	mov word[linha_de_comando], 'in'
	mov word[linha_de_comando + 2], 't '
	mov byte[linha_de_comando + 4], '0'
	inc di
	call HexToAscii		; ax <- 'XY'
	mov word[linha_de_comando + 5], ax
	mov byte[linha_de_comando + 7],'h'
	mov byte[linha_de_comando + 8],10
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
;loop IP+XYh
caseE2:
	mov cx, 14
	mov word[linha_de_comando], 'lo'
	mov word[linha_de_comando + 2], 'op'
	mov word[linha_de_comando + 4], '  '	
	mov word[linha_de_comando + 6], 'IP'
	mov byte[linha_de_comando + 8], '+'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret		
;jcxz IP+XYh
caseE3:
	mov cx, 14
	mov word[linha_de_comando], 'jc'
	mov word[linha_de_comando + 2], 'xz'
	mov word[linha_de_comando + 4], '  '	
	mov word[linha_de_comando + 6], 'IP'
	mov byte[linha_de_comando + 8], '+'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 10], ax
	mov byte[linha_de_comando + 12], 'h'
	mov byte[linha_de_comando + 13], 10
	ret	
	
;in  AL, XYh
caseE4:
	mov cx, 12
	mov word[linha_de_comando], 'in'
	mov word[linha_de_comando + 2], '  '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;in  AX, XYh
caseE5:
	mov cx, 12
	mov word[linha_de_comando], 'in'
	mov word[linha_de_comando + 2], '  '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;out  AL, XYh
caseE6:
	mov cx, 12
	mov word[linha_de_comando], 'ou'
	mov word[linha_de_comando + 2], 't '
	mov word[linha_de_comando + 4], 'AL'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;out  AX, XYh	
caseE7:
	mov cx, 12
	mov word[linha_de_comando], 'ou'
	mov word[linha_de_comando + 2], 't '
	mov word[linha_de_comando + 4], 'AX'
	mov word[linha_de_comando + 6], ', '
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	mov byte[linha_de_comando + 10], 'h'
	mov byte[linha_de_comando + 11], 10
	ret	
;call near IP+XYZWh
caseE8:
	mov cx, 22
	mov word[linha_de_comando], 'ca'
	mov word[linha_de_comando + 2], 'll'
	mov word[linha_de_comando + 4], ' n'
	mov word[linha_de_comando + 8], 'ea'
	mov word[linha_de_comando + 10], 'r '
	mov word[linha_de_comando + 12], 'IP'
	mov byte[linha_de_comando + 14], '+'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 18], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 16], ax	
	mov byte[linha_de_comando + 20], 'h'
	mov byte[linha_de_comando + 21], 10
	ret
;jmp near IP+XYZWh
caseE9:
	mov cx, 22
	mov word[linha_de_comando], 'jm'
	mov word[linha_de_comando + 2], 'p '
	mov word[linha_de_comando + 4], 'ne'
	mov word[linha_de_comando + 8], 'ar'
	mov word[linha_de_comando + 10], '  '
	mov word[linha_de_comando + 12], 'IP'
	mov byte[linha_de_comando + 14], '+'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 18], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 16], ax	
	mov byte[linha_de_comando + 20], 'h'
	mov byte[linha_de_comando + 21], 10
	ret
;jmp [cs:ip]
caseEA:
	mov cx, 18
	mov word[linha_de_comando], 'jm'
	mov word[linha_de_comando + 2], 'p '
	mov word[linha_de_comando + 4], ' ['
	inc di
	call HexToAscii
	mov word[linha_de_comando + 14], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 12], ax
	mov word[linha_de_comando + 10], 'h:'	
	inc di
	call HexToAscii
	mov word[linha_de_comando + 8], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + 6], ax	
	mov byte[linha_de_comando + 16], 'h'
	mov byte[linha_de_comando + 17], 10
	ret
;jmp short IP+XYh
caseEB:
	mov cx, 22
	mov word[linha_de_comando], 'jm'
	mov word[linha_de_comando + 2], 'p '
	mov word[linha_de_comando + 4], 'sh'
	mov word[linha_de_comando + 8], 'or'
	mov word[linha_de_comando + 10], 't '
	mov word[linha_de_comando + 12], '  '	
	mov word[linha_de_comando + 14], 'IP'
	mov byte[linha_de_comando + 16], '+'
	inc di
	call HexToAscii
	mov word[linha_de_comando + 18], ax
	mov byte[linha_de_comando + 20], 'h'
	mov byte[linha_de_comando + 21], 10
	ret	
;;in AL, DX
caseEC:
	mov cx, 11
	mov word[linha_de_comando],'ou'
	mov word[linha_de_comando + 2],'t '
	mov word[linha_de_comando + 4],'AL'
	mov word[linha_de_comando + 6],', '
	mov word[linha_de_comando + 8],'DX'  	
	mov byte[linha_de_comando + 10],10
	ret	
;;in AX, DX
caseED:
	mov cx, 11
	mov word[linha_de_comando],'ou'
	mov word[linha_de_comando + 2],'  '
	mov word[linha_de_comando + 4],'AX'
	mov word[linha_de_comando + 6],', '
	mov word[linha_de_comando + 8],'DX'  	
	mov byte[linha_de_comando + 10],10
	ret	
;;out AL, DX
caseEE:	
	mov cx, 11
	mov word[linha_de_comando],'ou'
	mov word[linha_de_comando + 2],'t ' 
	mov word[linha_de_comando + 4],'AL'
	mov word[linha_de_comando + 6],', '
	mov word[linha_de_comando + 8],'DX'  	
	mov byte[linha_de_comando + 10],10
	ret
;;out AX, DX
caseEF:	
	mov cx, 11
	mov word[linha_de_comando],'ou'
	mov word[linha_de_comando + 2],'t '
	mov word[linha_de_comando + 4],'AX'
	mov word[linha_de_comando + 6],', '
	mov word[linha_de_comando + 8],'DX'  	
	mov byte[linha_de_comando + 10],10
	ret

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
	ret
;;stc
caseF9:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'c'
	mov byte[linha_de_comando + 3],10
	ret
;;cli
caseFA:
	mov cx, 4
	mov word[linha_de_comando],'cl'
	mov byte[linha_de_comando + 2],'i'
	mov byte[linha_de_comando + 3],10
	ret
;;sti
caseFB:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'i'
	mov byte[linha_de_comando + 3],10
	ret
;;cld
caseFC:
	mov cx, 4
	mov word[linha_de_comando],'cl'
	mov byte[linha_de_comando + 2],'d'
	mov byte[linha_de_comando + 3],10
	ret
;;std
caseFD:
	mov cx, 4
	mov word[linha_de_comando],'st'
	mov byte[linha_de_comando + 2],'d'
	mov byte[linha_de_comando + 3],10	
	ret
	
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



;; Funcoes de insercao, no vetor 'linha_de_comando': um endereco de mem ou reg,
;; de acordo com as especificacoes
;; Entrada:	DI <- posicao do byte 'mod r/m reg'
;; 		BX <- posicao do vetor 'linha_de_comando' para o proximo caracter
;; Saidas:	CX <- numero total de letras em 'linha_de_comando'
	
;; reg16/mem16, reg16
RMDestino16:
	push si
	mov al, byte[es:bin + di] ; al <- byte 'mod reg r/m'
	mov ah, al
	and ah, 11000000b	; ah <- apenas os 2 bits de mod
	cmp ah, 11000000b
	je RMDestino16mod11
	
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
	ret

;; r/m eh tratado como um registrador
RMDestino16mod11:
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
	ret

;; reg8/mem8, reg8
RMDestino8:
;;; ...
	
;; reg16, reg16/mem16
RMFonte16:
;;; ...

;; reg 8, reg8/mem8
RMFonte8:
;;; ...




	
;; Funcao que insere a memoria referenciada na linha de comando
;; Entrada:	BX <- inicio para a escrita
;;		DI <- indice para o byte 'mod reg r/m'
;; 		AL <- byte 'mod reg r/m'
;; Saida:	BX <- inicio para a escrita posterior
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
	je InsereMemoria110Ponte
	cmp ah, 00000111b
	je InsereMemoria111Ponte

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
InsereMemoria110Ponte:
	jmp InsereMemoria110
InsereMemoria111Ponte:
	jmp InsereMemoria111
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
	mov word[linha_de_comando + bx + 2], ax
	inc di
	call HexToAscii
	mov word[linha_de_comando + bx + 4], ax
	mov byte[linha_de_comando + bx + 6], 'h'
	pop ax
	add bx, 7
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
