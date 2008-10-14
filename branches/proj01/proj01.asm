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
	;; para a verificacao, serao lidos os 34 primeiros bytes do arquivo,
	;; que contem algumas informacoes do cabecalho.
	
	;; leitura dos bytes
	mov ah, 0x3F		; servico de leitura
	mov bx, [handle_arq_in]
	mov cx, 34		; n de bytes a serem lidos
	mov dx, inicio_cabecalho
	int 0x21
	
	;; verificacao do tipo do arquivo (2 primeiros bytes)
	cmp word [inicio_cabecalho], 'BM'		; o identificador do arquivo deve ser 'BM'
	jne ErroImagem

	;; verificacao do numero de bits/pixel
	cmp word [inicio_cabecalho + 0x1C], 24		; o numero de bits/pixel deve ser 24
	jne ErroImagem

	;; verificacao do tipo de compressao do arquivo
	cmp word [inicio_cabecalho + 0x1E], 0
	jne ErroImagem
	cmp word [inicio_cabecalho + 0x20], 0		; o valor de compressao deve ser 0 para os dois bytes
	jne ErroImagem

	;; Se a execucao chegar ate aqui, o arquivo esta OK!
	jmp CarregaImagem
	
ErroImagem:
	;; arquivo nao esta no formato especificado.
	;; fecha o arquivo
	mov ah, 0x3E
	;; como a leitura n afeta bx, este continua tendo o valor do handle do arquivo
	int 0x21
	mov ah, 9
	mov dx, MsgErroArquivo
	int 0x21
	jmp Fim
	

CarregaImagem:	
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
	
	;; tamanho do arquivo
	;; assumiremos que o arquivo tem no maximo 64K, entao os 2 ultimos bytes que representam
	;; o tamanho estarao necessariamente zerados
	;; portanto, apenas os dois primeiros bytes importam
	mov cx, [inicio_cabecalho + 2] ; cx <- tamanho do arquivo em bytes

	;; para a leitura, colocaremos o valor de ES temporariamente em DS
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
	and ax, 0x03		; al <- ax%4
	mov word [apendice], ax

	
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
	;; DI -> apontador do primeiro byte do pixel lido
	;; SI -> sera usado na verificacao das bordas do pixel

	xor ax, ax		; zera contador para altura

	push di			; guarda di na memoria
	xor di, di		; zera o apontador para o byte atual

ForAltura:	
	xor cx, cx		; zera contador para largura a cada nova linha

ForLargura:
	call SePreto		; Retora dl=1 se o pixel for preto e dl=0 caso contrario
	cmp dl, 0	
	je VoltaForLargura	; se o pixel NAO for preto, continua verificando
	call VerificaVizinhos	; caso contrario, chama a rotina de verificacao dos vizinhos

	
VoltaForLargura:
	add di, 3		; soma 3 bytes ao contador de deslocamento
	inc cx
	cmp cx, [es:img + 0x12]	; se cx == largura da imagem,
	je SaiForLargura	; ja percorreu todos os pixels daquela linha
	jmp ForLargura

SaiForLargura:
	add di, [apendice]	; soma o apendice ao contador de deslocamento
	inc ax
	cmp ax, [es:img + 0x16]	; se ax NAO for igual a altura, ainda nao chegou ao fim,
				; entao volta para o for inicial
	jne ForAltura		; caso contrario, ja verificou todos os pixels e pula para
	jmp GeraArquivo		; a geracao do arquivo


	;; Daqui pra baixo, estao as definicoes das rotinas utilizadas

;; rotina para verificar se um dado pixel eh branco
;; retorna dl=1 p/ pixel branco
;;	   dl=0 caso contrario 
SeBranco:	
	cmp word [es:img + 0x36 + bx], 0xFFFF
	je ContinuaSeBranco
	mov dl, 0		; se os dois primeiros bytes nao forem 0xFF e 0xFF
	ret			; ja retorna que o pixel nao eh branco
ContinuaSeBranco:
	cmp byte [es:img + 0x38 + bx], 0xFF  ; [es:img + 0x36 + bx + 2]
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
	cmp word [es:img + 0x36 + di], 0x0000
	je ContinuaSePreto
	mov dl, 0		; se os dois primeiros bytes nao forem 0x00 e 0x00
	ret			; ja retorna que o pixel nao eh branco
ContinuaSePreto:
	cmp byte [es:img + 0x38 + di], 0x00 ; [es:img + 0x36 + di + 2]
	je FimSePreto
	mov dl, 0
	ret
FimSePreto:
	mov dl, 1		; se chegar ate aqui, o pixel eh preto
	ret


;; rotina para verificar cada um dos vizinhos de um pixel preto
;; e pinta-lo se for branco
VerificaVizinhos:		
	;; SI contera o "estado" do pixel em relacao as bordas.
	;; Os 4 ultimos bits serao flags para dizer se o pixel esta em algum
	;; limite das bordas.
	;; SI: 0000 0000 0000 [bEsq][bCima][bDir][bBaixo]
	;; 0 -> OK. 1 -> problema para aquela direcao

	push si			; guarda si na pilha
	xor si, si		; zera o registrador das "flags'

	;; verifica o pixel da ESQUERDA
	
	;; verifica borda pela esquerda
	cmp cx, 0		; caso a coluna atual seja a primeira, 
	je SetBitEsq		; pula ao proximo vizinho
	
	mov bx, di
	sub bx, 3		; bx <- di-3
	call SeBranco
	cmp dl, 0		; caso pixel NAO seja branco, pula ao prox
	je PixelDireita
	mov word [es:img + 0x36 + bx], 0x0000 ; caso contrario, PINTA-O
	jmp PixelDireita
SetBitEsq:
	or si, 0x0008		; seta o bit da esquerda de SI
PixelDireita:
	;; verifica o pixel da DIREITA

	;; verifica borda pela direita
	mov bx, cx
	inc bx
	cmp bx, [es:img + 0x12]
	je SetBitDir

	mov bx, di
	add bx, 3		; bx <- di+3
	call SeBranco
	cmp dl, 0
	je PixelAbaixo
	mov word [es:img + 0x36 + bx], 0x0000
	jmp PixelAbaixo
SetBitDir:
	or si, 0x0002
PixelAbaixo:	
	;; verifica o pixel ABAIXO

	;; verifica borda de baixo
	cmp ax, 0
	je SetBitBaixo
	
	;; bx <- di - ([largura]*3 + [apendice])
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	neg bx
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelAcima
	mov word [es:img + 0x36 + bx], 0x0000
	jmp PixelAcima
SetBitBaixo:	
	or si, 0x0001
PixelAcima:	
	;; verifica o pixel ACIMA

	;; verifica borda de cima
	mov bx, ax
	inc bx
	cmp bx, [es:img + 0x16]
	je SetBitCima
	
	;; bx <- di + ([largura]*3 + [apendice])
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelInfEsq
	mov word [es:img + 0x36 + bx], 0x0000
	jmp PixelInfEsq
SetBitCima:	
	or si, 4
PixelInfEsq:
	;; verifica o pixel INFERIOR ESQUERDO

	;; verifica borda de baixo
	test si, 0x0001
	jnz PixelInfDir

	;; verifica borda da esquerda
	test si, 0x0008
	jnz PixelInfDir

	;; bx <- di - ([largura]*3 + [apendice] + 3)
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	add bx, 3
	neg bx
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelInfDir
	mov word [es:img + 0x36 + bx], 0x0000
PixelInfDir:
	;; verifica o pixel INFERIOR DIREITO

	;; verifica borda de baixo
	test si, 0x0001
	jnz PixelSupEsq

	;; verifica borda da direita
	test si, 0x0002
	jnz PixelSupEsq

	;; bx <- di - ([largura]*3 + [apendice] - 3)
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	sub bx, 3
	neg bx
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelSupEsq
	mov word [es:img + 0x36 + bx], 0x0000
PixelSupEsq:
	;; verifica o pixel SUPERIOR ESQUERDO

	;; verifica a borda de cima
	test si, 0x0004
	jnz PixelSupDir

	;; verifica a borda da esquerda
	test si, 0x0008
	jnz PixelInfDir

	;; bx <- di + ([largura]*3 + [apendice]) -3
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	sub bx, 3
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelSupEsq
	mov word [es:img + 0x36 + bx], 0x0000
PixelSupDir:	
	;; verifica o pixel SUPERIOR DIREITO

	;; verifica a borda de cima
	test si, 0x0003
	jnz FimVerificaVizinhos

	;; verifica a borda da direita
	test si, 0x0002
	jnz FimVerificaVizinhos

	;; bx <- di + ([largura]*3 + [apendice]) +3
	mov bx,[es:img + 0x12]	
	shl bx, 1
	add bx,[es:img + 0x12]
	add bx, [apendice]
	add bx, 3
	add bx, di
	call SeBranco
	cmp dl, 0
	je PixelSupEsq
	mov word [es:img + 0x36 + bx], 0x0000
FimVerificaVizinhos:
	pop si			; recupera si
	ret


	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; processamento da imagem ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; _____________________________________________________________


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; geracao do arquivo de saida ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GeraArquivo:
	;; recupera o di utilizado no processamento da imagem
	pop di
	
	;; criacao do arquivo
	mov ah, 0x3C
	mov cx, 0x00
	mov dx, arq_out		; DS:DX -> apontador para o nome do arq em ASCIIZ
	int 0x21

	;; escrita no arquivo
	mov bx, ax		; bx <- handle para arquivo de saida
	mov cx, [inicio_cabecalho + 2]
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
inicio_cabecalho: resb 34

;; numero de bytes somado a cada linha (vai de 0 a 3)
apendice: resb 2
	
; _____________________________________________________________	
	
	
;; este segmento (ES) eh para guardar o arquivo inteiro na memoria.
SEGMENT data2
img:	resb 0xFFF0	; ~64K (ao colocar 0xFFFF, o tlink diz que o segmento excede 64K)
	
; _____________________________________________________________
	
SEGMENT stack stack
	resb 0xFF	;; 256
stacktop:
