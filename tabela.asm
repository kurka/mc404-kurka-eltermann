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
	




;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DECLARACOES
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





case00:	;0000 0000 mod reg r/m (disp-lo),(disp-hi) add  reg8/mem8, reg8 
case01:	;0000 0001 mod reg r/m (disp-lo),(disp-hi) add  reg16/mem16,reg16
case02:	;0000 0010 mod reg r/m (disp-lo),(disp-hi) add  reg8,reg8/mem8
case03:	;0000 0011 mod reg r/m (disp-lo),(disp-hi) add   reg16,reg16/mem16 
case04:	;0000 0100 data-8                          add  AL,immed8
case05:	;0000 0101 data-lo     data-hi             add  AX,immed16
case06:	;0000 0110                                 push ES
case07:	;0000 0111                                 pop  ES
case08:	;0000 0100 mod reg r/m (disp-lo),(disp-hi) or   reg8/mem8,reg8


case09:	;0000 1001 mod reg r/m (disp-lo),(disp-hi) or   reg16/mem16,reg16
case0A:	;0000 1010 mod reg r/m (disp-lo),(disp-hi) or   reg8,reg8/mem8
case0B:	;0000 1011 mod reg r/m (disp-lo),(disp-hi) or   reg16,reg16/mem16
case0C:	;0000 1100 data-8                          or   AL, immed8
case0D:	;0000 1101 data-lo     data-hi             or   AX,immed16
case0E:	;0000 1110                                 push CS
case0F:	;0000 1111                                 —
case10:	;0001 0000 mod reg r/m (disp-lo),(disp-hi) adc  reg8/mem8,reg8
case11:	;0001 0001 mod reg r/m (disp-lo),(disp-hi) adc   reg16/mem16,reg16
case12:	;0001 0010 mod reg r/m (disp-lo),(disp-hi) adc  reg8,reg8/mem8
case13:	;0001 0011 mod reg r/m (disp-lo),(disp-hi) adc   reg16,reg16/mem16
case14:	;0001 0100 data-8                          adc  AL,immed8
case15:	;0001 0101 data-lo     data-hi             adc  AX,immed16
case16:	;0001 0110                                 push SS
case17:	;0001 0111                                 pop  SS
case18:	;0001 1000 mod reg r/m (disp-lo),(disp-hi) sbb  reg8/mem8,reg8
case19:	;0001 1001 mod reg r/m (disp-lo),(disp-hi) sbb   reg16/mem16,reg16
case1A:	;0001 1010 mod reg r/m (disp-lo),(disp-hi) sbb  reg8,reg8/mem8
case1B:	;0001 1011 mod reg r/m (disp-lo),(disp-hi) sbb   reg16,reg16/mem16
                                             sbb  AL,immed8
case1C:	;0001 1100 data-8
case1D:	;0001 1101 data-lo     data-hi             sbb  AX,immed16
case1E:	;0001 1110                                 push DS
case1F:	;0001 1111                                 pop  DS
case20:	;0010 0000 mod reg r/m (disp-lo),(disp-hi) and  reg8/mem8,reg8
case21:	;0010 0001 mod reg r/m (disp-lo),(disp-hi) and   reg16/mem16,reg16
case22:	;0010 0010 mod reg r/m (disp-lo),(disp-hi) and  reg8,reg8/mem8
case23:	;0010 0011 mod reg r/m (disp-lo),(disp-hi) and   reg16,reg16/mem16
case24:	;0010 0100 data-8                          and  AL,immed8
case25:	;0010 0101 data-lo     data-hi             and  AX,immed16
case26:	;0010 0110                                 ES:  (segment override prefix)
case27:	;0010 0111                                 daa
case28:	;0010 1000 mod reg r/m (disp-lo),(disp-hi) sub  reg8/mem8,reg8
case29:	;0010 1001 mod reg r/m (disp-lo),(disp-hi) sub   reg16/mem16,reg16
case2A:	;0010 1010 mod reg r/m (disp-lo),(disp-hi) sub  reg8,reg8/mem8
case2B:	;0010 1011 mod reg r/m (disp-lo),(disp-hi) sub   reg16,reg16/mem16
case2C:	;0010 1100 data-8                          sub  AL,immed8
case2D:	;0010 1101 data-lo     data-hi             sub  AX,immed16
case2E:	;0010 1110                                 DS:  (segment override prefix)
case2F:	;0010 1111                                 das
case30:	;0011 0000 mod reg r/m (disp-lo),(disp-hi) xor  reg8/mem8,reg8
case31:	;0011 0001 mod reg r/m (disp-lo),(disp-hi) xor   reg16/mem16,reg16
case32:	;0011 0010 mod reg r/m (disp-lo),(disp-hi) xor  reg8,reg8/mem8
case33:	;0011 0011 mod reg r/m (disp-lo),(disp-hi) xor  reg16,reg16/mem16
case34:	;0011 0100 data-8                          xor  AL,immed8
case35:	;0011 0101 data-lo     data-hi             xor  AX,immed16
case36:	;0011 0110                                 SS:  (segment override prefix)
case37:	;0011 0111                                 aaa
case38:	;0011 1000 mod reg r/m (disp-lo),(disp-hi) xor  reg8/mem8,reg8
case39:	;0011 1001 mod reg r/m (disp-lo),(disp-hi) xor  reg16/mem16,reg16
case3A:	;0011 1010 mod reg r/m (disp-lo),(disp-hi) xor  reg8,reg8/mem8
case3B:	;0011 1011 mod reg r/m (disp-lo),(disp-hi) xor  reg16,reg16/mem16
case3C:	;0011 1100 data-8                          xor  AL,immed8
case3D:	;0011 1101 data-lo     data-hi             xor  AX,immed16
case3E:	;0011 1110                                 DS:  (segment override prefix)
case3F:	;0011 1111                                 aas
case40:	;0100 0000                                 inc  AX
	; inc  CX 
case41:	;0100 0001
case42:	;0100 0010                                 inc  DX
case43:	;0100 0011                                 inc  BX
case44:	;0100 0100                                 inc  SP
case45:	;0100 0101                                 inc  BP
case46:	;0100 0110                                 inc  SI
case47:	;0100 0111                                 inc  DI
case48:	;0100 1000                                 dec  AX
case49:	;0100 1001                                 dec  CX
	;;        dec  DX
case4A:	;0100 1010
case4B:	;0100 1011                                 dec  BX
case4C:	;0100 1100                                 dec  SP
case4D:	;0100 1101                                 dec  BP
case4E:	;0100 1110                                 dec  SI
case4F:	;0100 1111                                 dec  DI
case50:	;0101 0000                                 push AX
case51:	;0101 0001                                 push CX
	;;        push DX
case52:	;0101 0010
case53:	;0101 0011                              push        BX
case54:	;0101 0100                              push        SP
case55:	;0101 0101                              push        BP
case56:	;0101 0110                              push        SI
case57:	;0101 0111                              push        DI
case58:	;0101 1000                              pop         AX
case59:	;0101 1001                              pop         CX
case5A:	;0101 1010                              pop         DX
case5B:	;0101 1011                              pop         BX
case5C:	;0101 1100                              pop         SP
case5D:	;0101 1101                              pop         BP
case5E:	;0101 1110                              pop         SI
case5F:	;0101 1111                              pop         DI
case60:	;0110 0000                              pusha
case61:	;0110 0001                              popa
case62:	;0110 0010 mod reg r/m                  bound       reg16,mem16
case63:	;0110 0011                              —
case64:	;0110 0100                              —
case65:	;0110 0101                              —
	;;        —
case66:	;0110 0110
case67:	;0110 0111                              —
case68:	;0110 1000 data-lo     data-hi          push        immed16
case69:	;0110 1001 mod reg r/m data-lo, data-hi imul        immed16
case70:	;0111 0000 IP-inc-8                     jo          short-label
case71:	;0111 0001 IP-inc-8                     jno         short-label
case72:	;0111 0010 IP-inc-8                     jb/jnae/jc   short-label
case73:	;0111 0011 IP-inc-8                     jnb/jae/jnc  short-label
case74:	;0111 0100 IP-inc-8                     je/jz       short-label
case75:	;0111 0101 IP-inc-8                     jne/jnz     short-label
case76:	;0111 0110 IP-inc-8                     jbe/jna     short-label
	;;        jnbe/ja     short-label
case77:	;0111 0111 IP-inc-8
case78:	;0111 1000 IP-inc-8                     js          short-label
case79:	;0111 1001 IP-inc-8                     jns         short-label
case7A:	;0111 1010 IP-inc-8                     jp/jpe      short-label
case7B:	;0111 1011 IP-inc-8                     jnp/jpo     short-label
case7C:	;0111 1100 IP-inc-8                     jl/jnge     short-label
case7D:	;0111 1101 IP-inc-8                     jnl/jge     short-label
case7E:	;0111 1110 IP-inc-8 jle/jng short-label
case7F:	;0111 1111 IP-inc-8 jnle/jg short-label

case80: ;1000 0000 mod 000 r/m (disp-lo),(disp-hi), data-8          add reg8/mem8,immed8
	;;         mod 001 r/m (disp-lo),(disp-hi), data-8          or  reg8/mem8,immed8 
	;; 	mod 010 r/m (disp-lo),(disp-hi), data-8          adc reg8/mem8,immed8
	;; 	mod 011 r/m (disp-lo),(disp-hi), data-8          sbb reg8/mem8,immed8
	;; 	mod 100 r/m (disp-lo),(disp-hi), data-8          and reg8/mem8,immed8
	;; 	mod 101 r/m (disp-lo),(disp-hi), data-8          sub reg8/mem8,immed8
	;; 	mod 110 r/m (disp-lo),(disp-hi), data-8          xor reg8/mem8,immed8
	;; 	mod 111 r/m (disp-lo),(disp-hi), data-8          cmp reg8/mem8,immed8
case81:	;	1000 0001 mod 000 r/m (disp-lo),(disp-hi), data-lo,data-hi add reg16/mem16,immed16
	;; 	mod 001 r/m (disp-lo),(disp-hi), data-lo,data-hi or  reg16/mem16,immed16
	;; 	mod 010 r/m (disp-lo),(disp-hi), data-lo,data-hi adc reg16/mem16,immed16
	;; 	mod 011 r/m (disp-lo),(disp-hi), data-lo,data-hi sbb reg16/mem16,immed16
	;; 	mod 100 r/m (disp-lo),(disp-hi), data-lo,data-hi and reg16/mem16,immed16
case81:	;	1000 0001 mod 101 r/m (disp-lo),(disp-hi), data-lo,data-hi sub reg16/mem16,immed16
	;; 	mod 110 r/m (disp-lo),(disp-hi), data-lo,data-hi xor reg16/mem16,immed16
	;; 	mod 111 r/m (disp-lo),(disp-hi), data-lo,data-hi cmp reg16/mem16,immed16
case82:	;	1000 0010 mod 000 r/m (disp-lo),(disp-hi), data-8          add reg8/mem8,immed8
	;;         —
	;; 	mod 001 r/m
	;; 	mod 010 r/m (disp-lo),(disp-hi), data-8          adc reg8/mem8,immed8
	;; 	mod 011 r/m (disp-lo),(disp-hi), data-8          sbb reg8/mem8,immed8
	;; 	mod 100 r/m                                      —
	;; 	mod 101 r/m (disp-lo),(disp-hi), data-8          sub reg8/mem8,immed8
	;; 	mod 110 r/m                                      —
	;; 	mod 111 r/m (disp-lo),(disp-hi), data-8          cmp reg8/mem8,immed8
case83:	;	1000 0011 mod 000 r/m (disp-lo),(disp-hi), data-SX         add reg16/mem16,immed8
	;; 	mod 001 r/m                                      —
	;; 	mod 010 r/m (disp-lo),(disp-hi), data-SX         adc  reg16/mem16,immed8
	;; 	mod 011 r/m (disp-lo),(disp-hi), data-SX         sbb reg16/mem16,immed8
	;; 	mod 100 r/m                                      —
	;; 	mod 101 r/m (disp-lo),(disp-hi), data-SX         sub  reg16/mem16,immed8
	;; 	mod 110 r/m                                      —
	;; 	mod 111 r/m (disp-lo),(disp-hi), data-SX         cmp  reg16/mem16,immed8
case84:	;1000 0100 mod reg r/m (disp-lo),(disp-hi) test reg8/mem8,reg8
case85:	;1000 0101 mod reg r/m (disp-lo),(disp-hi) test reg16/mem16,reg16
case86:	;1000 0110 mod reg r/m (disp-lo),(disp-hi) xchg reg8,reg8/mem8
case87:	;1000 0111 mod reg r/m (disp-lo),(disp-hi) xchg reg16,reg16/mem16
case88:	;1000 0100 mod reg r/m (disp-lo),(disp-hi) mov  reg8/mem8,reg8
case89:	;1000 1001 mod reg r/m (disp-lo),(disp-hi) mov   reg16/mem16,reg16
case8A:	;1000 1010 mod reg r/m (disp-lo),(disp-hi) mov  reg8,reg8/mem8
case8B:	;1000 1011 mod reg r/m (disp-lo),(disp-hi) mov   reg16,reg16/mem16
case8C:	;1000 1100 mod OSR r/m (disp-lo),(disp-hi) mov   reg16/mem16,SEGREG
	;; mod 1 - r/m                     —
case8D:	;1000 1101 mod reg r/m (disp-lo),(disp-hi)   lea   reg16,mem16
case8E:	;1000 1110 mod OSR r/m (disp-lo),(disp-hi)   mov    SEGREG,reg16/mem16
	;; mod 1 - r/m                       —
case8F:	;1000 1111                                   pop   mem16
case90:	;1001 0000                                   nop   (xchg AX,AX)
case91:	;1001 0001                                   xchg  AX,CX
case92:	;1001 0010                                   xchg  AX,DX
case93:	;1001 0011                                   xchg  AX,BX
case94:	;1001 0100                                   xchg  AX,SP
case95:	;1001 0101                                   xchg  AX,BP
case96:	;1001 0110                                   xchg  AX,SI
case97:	;1001 0111                                   xchg  AX,DI
	;;        cbw
case98:	;1001 1000
case99:	;1001 1001                                   cwd
case9A:	;1001 1010 disp-lo     disp-hi,seg-lo,seg-hi call  far-proc
case9B:	;1001 1011                                   wait
case9C:	;1001 1100                                   pushf
case9D:	;1001 1101                                   popf
case9E:	;1001 1110                                   sahf
case9F:	;1001 1111                                   lahf
caseA0:	;1010 0000 addr-lo     addr-hi               mov   AL,mem8
caseA1:	;1010 0001 addr-lo     addr-hi               mov   AX,mem16
caseA2:	;1010 0010 addr-lo     addr-hi               mov   mem8,AL
caseA3:	;1010 0011 addr-lo     addr-hi               mov   mem16,AL
caseA4:	;1010 0100                                   movs   dest-str8,src-str8
caseA5:	;1010 0101                                   movs  dest-str16,src-str16
	;;        cmps   dest-str8,src-str8
caseA6:	;1010 0110
caseA7:	;1010 0111                                   cmps  dest-str16,src-str16
caseA8:	;1010 1000 data-8                            test  AL,immed8
caseA9:	;1010 1001 data-lo     data-hi               test  AX,immed16
caseAA:	;1010 1010                     stos    dest-str8
caseAB:	;1010 1011                     stos    dest-str16
caseAC:	;1010 1100                     lods    src-str8
caseAD:	;1010 1101                     lods    src-str16
caseAE:	;1010 1110                     scas    dest-str8
caseAF:	;1010 1111                     scas    dest-str16
caseB0:	;1011 0000 data-8              mov     AL,immed8
caseB1:	;1011 0001 data-8              mov     CL,immed8
caseB2:	;1011 0010 data-8              mov     DL,immed8
caseB3:	;1011 0011 data-8              mov     BL,immed8
caseB4:	;1011 0100 data-8              mov     AH,immed8
caseB5:	;1011 0101 data-8              mov     CH,immed8
caseB6:	;1011 0110 data-8              mov     DH,immed8
caseB7:	;1011 0111 data-8              mov     BH,immed8
caseB8:	;1011 1000 data-lo     data-hi mov     AX,immed16
caseB9:	;1011 1001 data-lo     data-hi mov     CX,immed16
caseBA:	;1011 1010 data-lo     data-hi mov     DX,immed16
caseBB:	;1011 1011 data-lo     data-hi mov     BX,immed16
caseBC:	;1011 1100 data-lo     data-hi mov     SP,immed16
caseBD:	;1011 1101 data-lo     data-hi mov     BP,immed16
caseBE:	;1011 1110 data-lo     data-hi mov     SI,immed16
caseBF:	;1011 1111 data-lo     data-hi mov     DI,immed16
caseC0:	;1100 0000 mod 000 r/m data-8  rol     reg8/mem8, immed8
	;; mod 001 r/m data-8  ror     reg8/mem8, immed8
	;; mod 010 r/m data-8  rcl     reg8/mem8, immed8
	;; mod 011 r/m data-8  rcr     reg8/mem8, immed8
	;; mod 100 r/m data-8  shl/sal reg8/mem8, immed8
	;; mod 101 r/m data-8  shr     reg8/mem8, immed8
	;; mod 110 r/m         —
	;; mod 111 r/m data-8  sar     reg8/mem8, immed8
caseC1:	;1100 0001 mod 000 r/m data-8  rol     reg16/mem16, immed8
	;; mod 001 r/m data-8  ror     reg16/mem16, immed8
	;; mod 010 r/m data-8  rcl     reg16/mem16, immed8
	;; mod 011 r/m data-8  rcr     reg16/mem16, immed8
	;; mod 100 r/m data-8  shl/sal reg16/mem16, immed8
	;; mod 101 r/m data-8  shr     reg16/mem16, immed8
	;; mod 110 r/m         —
	;; mod 111 r/m data-8 sar reg16/mem16, immed8
caseC2:	;1100 0010 data-lo     data-hi                             ret     immed16 (intrasegment)
caseC3:	;1100 0011                                                 ret     (intrasegment)
caseC4:	;1100 0100 mod reg r/m (disp-lo),(disp-hi)                 les     reg16,mem16
caseC5:	;1100 0101 mod reg r/m (disp-lo),(disp-hi)                 lds     reg16,mem16
caseC6:	;1100 0110 mod 000 r/m (disp-lo),(disp-hi),data-8          mov     mem8,immed8
	;; mod 001 r/m                                     —
	;; mod 010 r/m                                     —
	;; mod 011 r/m                                     —
	;; mod 100 r/m                                     —
	;; mod 101 r/m                                     —
	;; mod 110 r/m                                     —
caseC6:	;1100 0110 mod 111 r/m                                     —
	;;        mov     mem16,immed16
caseC7:	;1100 0111 mod 000 r/m (disp-lo),(disp-hi),data-lo,data-hi
	;; mod 001 r/m                                     —
	;; mod 010 r/m                                     —
	;; mod 011 r/m                                     —
	;; mod 100 r/m                                     —
	;; mod 101 r/m                                     —
	;;        —
	;; mod 110 r/m
	;; mod 111 r/m                                     —
caseC8:	;1100 1000 data-lo     data-hi, level                      enter   immed16, immed8
caseC9:	;1100 1001                                                 leave
caseCA:	;1100 1010 data-lo     data-hi                             ret     immed16 (intersegment)
caseCB:	;1100 1011                                                 ret     (intersegment)
caseCC:	;1100 1100                                                 int     3
caseCD:	;1100 1101 data-8                                          int     immed8
caseCE:	;1100 1110                                                 into
	;;        iret
caseCF:	;1100 1111
caseD0:	;1101 0000 mod 000 r/m (disp-lo),(disp-hi)                 rol     reg8/mem8,1
	;; mod 001 r/m (disp-lo),(disp-hi)                 ror     reg8/mem8,1
	;; mod 010 r/m (disp-lo),(disp-hi)                 rcl     reg8/mem8,1
	;; mod 011 r/m (disp-lo),(disp-hi)                 rcr     reg8/mem8,1
	;; mod 100 r/m (disp-lo),(disp-hi)                 sal/shl reg8/mem8,1
	;; mod 101 r/m (disp-lo),(disp-hi)                 shr     reg8/mem8,1
	;;        —
	;; mod 110 r/m
	;; mod 111 r/m (disp-lo),(disp-hi)                 sar     reg8/mem8,1
caseD1:	;1101 0001 mod 000 r/m (disp-lo),(disp-hi) rol           reg16/mem16,1
	;; mod 001 r/m (disp-lo),(disp-hi) ror           reg16/mem16,1
caseD1:	;1101 0001 mod 010 r/m (disp-lo),(disp-hi) rcl           reg16/mem16,1
	;; mod 011 r/m (disp-lo),(disp-hi) rcr           reg16/mem16,1
	;; mod 100 r/m (disp-lo),(disp-hi) sal/shl        reg16/mem16,1
	;; mod 101 r/m (disp-lo),(disp-hi) shr           reg16/mem16,1
	;; mod 110 r/m                     —
	;;        (disp-lo),(disp-hi)
	;; mod 111 r/m                     sar           reg16/mem16,1
caseD2:	;1101 0010 mod 000 r/m (disp-lo),(disp-hi) rol           reg8/mem8,CL
	;; mod 001 r/m (disp-lo),(disp-hi) ror           reg8/mem8,CL
	;; mod 010 r/m (disp-lo),(disp-hi) rcl           reg8/mem8,CL
	;; mod 011 r/m (disp-lo),(disp-hi) rcr           reg8/mem8,CL
	;; mod 100 r/m (disp-lo),(disp-hi) sal/shl       reg8/mem8,CL
	;; mod 101 r/m (disp-lo),(disp-hi) shr           reg8/mem8,CL
	;; mod 110 r/m                     —
	;; mod 111 r/m (disp-lo),(disp-hi) sar           reg8/mem8,CL
caseD3:	;1101 0011 mod 000 r/m (disp-lo),(disp-hi) rol           reg16/mem16,CL
	;; mod 001 r/m (disp-lo),(disp-hi) ror           reg16/mem16,CL
	;; mod 010 r/m (disp-lo),(disp-hi) rcl           reg16/mem16,CL
	;; mod 011 r/m (disp-lo),(disp-hi) rcr           reg16/mem16,CL
	;; mod 100 r/m (disp-lo),(disp-hi) sal/shl        reg16/mem16,CL
	;; mod 101 r/m (disp-lo),(disp-hi) shr           reg16/mem16,CL
	;; mod 110 r/m                     —
	;; mod 111 r/m (disp-lo),(disp-hi) sar           reg16/mem16,CL
caseD4:	;1101 0100 0000 1010                       aam
caseD5:	;1101 0101 0000 1010                       aad
caseD6:	;1101 0110                                 —
caseD7:	;1101 0111                                 xlat          source-table
caseD8:	;1101 1000 mod 000 r/m (disp-lo),(disp-hi) esc           opcode,source
caseD9:	;1101 1001 mod 001 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDA:	;1101 1010 mod 010 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDB:	;1101 1011 mod 011 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDC:	;1101 1100 mod 100 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDD:	;1101 1101 mod 101 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDE:	;1101 1110 mod 110 r/m (disp-lo),(disp-hi) esc           opcode,source
caseDF:	;1101 1111 mod 111 r/m (disp-lo),(disp-hi) esc           opcode,source
caseE0:	;1110 0000 IP-inc-8                        loopne/loopnz  short-label
caseE1:	;1110 0001 IP-inc-8                                        loope/loopz    short-label
caseE2:	;1110 0010 IP-inc-8                                        loop          short-label
caseE3:	;1110 0011 IP-inc-8                                        jcxz          short-label
caseE4:	;1110 0100 data-8                                          in            AL,immed8
caseE5:	;1110 0101 data-8                                          in            AX,immed8
caseE6:	;1110 0110 data-8                                          out           AL,immed8
caseE7:	;1110 0111 data-8                                          out           AX,immed8
caseE8:	;1110 1000 IP-inc-lo   IP-inc-hi                           call          near-proc
caseE9:	;1110 1001 IP-inc-lo   IP-inc-hi                           jmp           near-label
caseEA:	;1110 1010 IP-lo       IP-hi,CS-lo,CS-hi                   jmp           far-label
caseEB:	;1110 1011 IP-inc-8                                        jmp           short-label
caseEC:	;1110 1100                                                 in            AL,DX
caseED:	;1110 1101                                                 in            AX,DX
caseEE:	;1110 1110                                                 out           AL,DX
caseEF:	;1110 1111                                                 out           AX,DX
caseF0:	;1111 0000                                                 lock          (prefix)
caseF1:	;1111 0001                                                 —
caseF2:	;1111 0010                                                 repne/repnz
caseF3:	;1111 0011                                                 rep/repe/repz
	;;        hlt
caseF4:	;1111 0100
caseF5:	;1111 0101                                                 cmc
caseF6:	;1111 0110 mod 000 r/m (disp-lo),(disp-hi),data-8          test           reg8/mem8,immed8
	;; mod 001 r/m                                     —
	;; mod 010 r/m (disp-lo),(disp-hi)                 not           reg8/mem8
	;; mod 011 r/m (disp-lo),(disp-hi)                 neg           reg8/mem8
	;; mod 100 r/m (disp-lo),(disp-hi)                 mul           reg8/mem8
	;; mod 101 r/m (disp-lo),(disp-hi)                 imul          reg8/mem8
	;; mod 110 r/m (disp-lo),(disp-hi)                 div           reg8/mem8
	;; mod 111 r/m (disp-lo),(disp-hi)                 idiv          reg8/mem8
caseF7:	;1111 0111 mod 000 r/m (disp-lo),(disp-hi),data-lo,data-hi test           reg16/mem16,immed16
	;; mod 001 r/m                                     —
	;; mod 010 r/m (disp-lo),(disp-hi)                 not           reg16/mem16
	;; mod 011 r/m (disp-lo),(disp-hi)                 neg           reg16/mem16
	;; mod 100 r/m (disp-lo),(disp-hi)                 mul           reg16/mem16
	;; mod 101 r/m (disp-lo),(disp-hi)                 imul          reg16/mem16
	;; mod 110 r/m (disp-lo),(disp-hi)                 div           reg16/mem16
	;; mod 111 r/m (disp-lo),(disp-hi)                 idiv          reg16/mem16
caseF8:	;1111 1000                                 clc
caseF9:	;1111 1001                                 stc
caseFA:	;1111 1010                                 cli
caseFB:	;1111 1011                                 sti
caseFC:	;1111 1100                                 cld
caseFD:	;1111 1101                                 std
caseFE:	;1111 1110 mod 000 r/m (disp-lo),(disp-hi) inc  mem16
	;; mod 001 r/m (disp-lo),(disp-hi) dec  mem16
	;; mod 010 r/m                     —
caseFE:	;1111 1110 mod 011 r/m                     —
	;; mod 100 r/m                     —
	;; mod 101 r/m                     —
	;; mod 110 r/m                     —
	;; mod 111 r/m                     —
caseFF:	;1111 1111 mod 000 r/m (disp-lo),(disp-hi) inc  mem16
	;; mod 001 r/m (disp-lo),(disp-hi) dec  mem16
	;; mod 010 r/m (disp-lo),(disp-hi) call reg16/mem16 (intrasegment)
	;; mod 011 r/m (disp-lo),(disp-hi) call mem16 (intersegment)
	;; mod 100 r/m (disp-lo),(disp-hi) jmp  reg16/mem16 (intrasegment)
	;; mod 101 r/m (disp-lo),(disp-hi) jmp  mem16 (intersegment)
	;; mod 110 r/m (disp-lo),(disp-hi) push mem16
	;; mod 111 r/m                     —	
	