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
	;; assumiremos que o arquivo tem no maximo 64K, entao os 2 ultimos bytes que representam
	;; o tamanho estarao necessariamente zerados
	;; portanto, apenas os dois primeiros bytes importam

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

	;; inicializacao de ES
	mov ax, data2
	mov es, ax
	
	;; para a leitura, colocaremos o valor de ES temporariamente em DS
	mov cx, [tamanho_arq]
	push ds			; guarda ds na pilha
	mov ax, es
	mov ds, ax
	mov dx, img		; DS:DX <- "ES:img"
	mov ah, 0x3F
	;; bx continua contendo o handle para o arquivo
	int 0x21		; arquivo eh salvo INTEIRO na memoria no segmento ES
	
	;; recupera ds
	pop ds

	;; fecha o arquivo de entrada
	mov ah, 0x3E
	;; bx continua contendo o handle para o arquivo
	int 0x21
	;; continua para o inicio do processamento da imagem
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; verificacao e leitura do arquivo para a memoria ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; _____________________________________________________________ 
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; processamento da imagem ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;; a altura e a largura da imagem estao, em pixels, gravadas em:
	;; largura -> [es:img + 0x12] (word)
	;; altura -> [es:img + 0x16] (word)
	;; como a imagem tem no maximo 64k, certamente o numero de pixels
	;; para qq uma das dimensoes eh <64k. Dessa forma, novamente,
	;; apenas os dois primeiros bytes importam.
	
	;; o n de bytes que forma uma linha da img deve ser multiplo de 4
	;; logo, deve-se somar um n de bytes a cada linha afim de normaliza-la
	;; 0 <= (numero de bytes a mais / linha)-chamemos de 'apendice' <= 3

	;; apendice = (largura*3)%4 [resto da divisao inteira]
	mov ax, [es:img + 0x12]	; ax <- largura
	mov bx, ax
	shl ax, 1		; ax <- 2*ax
	add ax, bx		; ax <- 2*ax + bx = 3*ax
	and al, 0x03		; al <- ax%4
	mov byte [apendice], al

	
	;; algoritmo do processamento (pseudo-codigo em alto nivel)
	;; para i de 0 até altura-1 {
	;;   para j de 0 até largura-1 {
	;;     verifica(pixel)
	;;     se (branco)-> continua no proximo pixel
	;;     se (preto) -> verifica(vizinhos)
	;;       enquanto houver vizinhos
	;;         se(branco)-> pinta de vermelho
	;;         caso contraio -> passa ao prox vizinho
	;;       fim enquanto
	;;     fim se(preto)
	;;   fim para(largura)
	;; fim para(altura)

	
	;; Inicio

	;; Como o arquivo nao apresenta a secao 'Color Map', a imagem
	;; comeca em -> es:img + 0x36

	;; Verificacao para cores:
	;; Memoria  [base] [b+1] [b+2]
	;; BRANCO:   0xFF, 0xFF, 0xFF
	;; PRETO:    0x00, 0x00, 0x00
	;; VERMELHO: 0x00, 0x00, 0xFF

	;; Registradores:
	;; AX -> contador para altura
	;; CX -> contador para largura
	;; DX -> verificacao dos bytes do pixel


	xor ax, ax		; zera contador para altura
	
ForAltura:	
	cmp ax, [es:img + 0x16]	; se ax == altura , ja verificou todos os pixels, 
	je GeraArquivo		; entao pula para a criacao do arquivo
	
	xor cx, cx		; zera contador para largura a cada nova linha

ForLargura:
	cmp cx, [es:img + 0x12]	; se cx == largura da imagem,
	je SaiForLargura	; ja percorreu todos os pixels daquela linha

	call SePreto
	cmp dl, 0		
	je VoltaForLargura	; se o pixel NAO for preto, continua verificando
	call VerificaVizinhos	; caso contrario, chama a rotina de verificacao dos vizinhos
	
VoltaForLargura:
	inc cx
	jmp ForLargura


SaiForLargura:
	inc ax
	jmp ForAltura

	
	;; Daqui pra baixo, estao as definicoes das rotinas utilizadas

;; rotina para verificar se um dado pixel eh branco
;; retorna dl=1 p/ pixel branco
;;	   dl=0 caso contrario 
SeBranco:	
	mov dx, [es:img + 0x36 + ??]
	cmp dx, 0xFFFF
	je ContinuaSeBranco
	mov dl, 0		; se os dois primeiros bytes nao forem 0xFF e 0xFF
	ret			; ja retorna que o pixel nao eh branco
ContinuaSeBranco:
	mov dh, [es:img + 0x38 + ??] ; [es:img + 0x36 + ?? + 2]
	cmp dh, 0xFF
	je FimSeBranco
	mov dl, 0
	ret
FimSeBranco:
	mov dl, 1		; se chegar ate aqui, o pixel eh branco
	ret


;; rotina para verificar se um dado pixel eh preto
;; retorna dl=1 p/ pixel preto
;;	   dl=0 caso contrario 
SePreto:	
	mov dx, [es:img + 0x36 + ??]
	cmp dx, 0x0000
	je ContinuaSePreto
	mov dl, 0		; se os dois primeiros bytes nao forem 0x00 e 0x00
	ret			; ja retorna que o pixel nao eh branco
ContinuaSePreto:
	mov dh, [es:img + 0x38 + ??] ; [es:img + 0x36 + ?? + 2]
	cmp dh, 0x00
	je FimSePreto
	mov dl, 0
	ret
FimSePreto:
	mov dl, 1		; se chegar ate aqui, o pixel eh preto
	ret


	
;; rotina para verificar cada um dos vizinhos de um pixel preto
;; e pinta-lo se for branco
VerificaVizinhos:	
	

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; processamento da imagem ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; geracao do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GeraArquivo:	
	;; criacao do arquivo
	mov ah, 0x3C
	mov cx, 0x00
	mov dx, arq_out		; DS:DX -> apontador para o nome do arq em ASCIIZ
	int 0x21

	;; escrita no arquivo
	mov bx, ax		; bx <- handle para arquivo de saida
	mov cx, [tamanho_arq]
	push ds			; guarda ds na pilha
	mov ax, es
	mov ds, ax		; ds <- (temporariamente) es
	mov dx, img		; dx <- offset para a imagem
	mov ah, 0x40		; servico de escrita
	int 0x21

	pop ds			; recupera ds

	;; fecha arquivo de saida
	mov ah, 0x3E
	;; bx continua contendo o handle do arquivo de saida
	int 0x21
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; geracao do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________
	
Fim:
	mov ah, 0x4C
	int 0x21

; _____________________________________________________________
	
;; segmento de dados
SEGMENT data

;; nomes dos arquivos de entrada e saida
arq_out: db 'saida.bmp',0x00

;; apontador (handle) para os arquivos de entrada e saida
handle_arq_in: resb 2

;; msg de erro
MsgErroFormato: db 'ERRO: Verifique se o nome do arquivo esta no formato imgXX.bmp',13,10,'$'
MsgErroAbreArquivo: db 'ERRO ao tentar abrir o arquivo. Verifique se o arquivo especificado esta no diretorio.',13,10,'$'
MsgErroArquivo:	db 'ERRO: O arquivo nao eh do tipo BMP especificado.',13,10,'$'
	
;; variaveis usadas na leitura do arquivo
tipo_arq: resb 2
tamanho_arq: resb 2

;; numero de bytes somado a cada linha (vai de 0 a 3)
apendice: resb 1
	
; _____________________________________________________________	
	
	
;; este segmento (ES) eh para guardar o arquivo inteiro na memoria.
SEGMENT data2
img:	resb 0xFFF0	; ~64K (ao colocar 0xFFFF, o tlink diz que o segmento excede 64K)
	
; _____________________________________________________________
	
SEGMENT stack stack
	resb 0xFF	;; 256
stacktop:
