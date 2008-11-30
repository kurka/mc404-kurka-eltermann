case04:	;0000 0100 data-8          add AL,immed8
case05:	;0000 0101 data-lo data-hi add AX,immed16 
case68:	;0110 1000 data-lo     data-hi          push        immed16
case69:	;0110 1001 mod reg r/m data-lo, data-hi imul        immed16
case70:	;0111 0000 IP-inc-8                     jo          short-label
case71:	;0111 0001 IP-inc-8                     jno         short-label
case72:	;0111 0010 IP-inc-8                     jb/jnae/jc   short-label
case73:	;0111 0011 IP-inc-8                     jnb/jae/jnc  short-label
case74:	;0111 0100 IP-inc-8                     je/jz       short-label
case75:	;0111 0101 IP-inc-8                     jne/jnz     short-label
case76:	;0111 0110 IP-inc-8                     jbe/jna     short-label
case77:	;0111 0111 IP-inc-8                     jnbe/ja     short-label 
case78:	;0111 1000 IP-inc-8                     js          short-label
case79:	;0111 1001 IP-inc-8                     jns         short-label
case7A:	;0111 1010 IP-inc-8                     jp/jpe      short-label
case7B:	;0111 1011 IP-inc-8                     jnp/jpo     short-label
case7C:	;0111 1100 IP-inc-8                     jl/jnge     short-label
case7D:	;0111 1101 IP-inc-8                     jnl/jge     short-label
case7E:	;0111 1110 IP-inc-8                     jle/jng short-label
case7F:	;0111 1111 IP-inc-8                     jnle/jg short-label
case80: ;1000 0000 mod 000 r/m (disp-lo),(disp-hi), data-8          add reg8/mem8,immed8
	;;             mod 001 r/m (disp-lo),(disp-hi), data-8          or  reg8/mem8,immed8 
	;; 	           mod 010 r/m (disp-lo),(disp-hi), data-8          adc reg8/mem8,immed8
	;; 	           mod 011 r/m (disp-lo),(disp-hi), data-8          sbb reg8/mem8,immed8
	;; 	           mod 100 r/m (disp-lo),(disp-hi), data-8          and reg8/mem8,immed8
	;; 	           mod 101 r/m (disp-lo),(disp-hi), data-8          sub reg8/mem8,immed8
	;; 	           mod 110 r/m (disp-lo),(disp-hi), data-8          xor reg8/mem8,immed8
	;; 	           mod 111 r/m (disp-lo),(disp-hi), data-8          cmp reg8/mem8,immed8
case81:	;1000 0001 mod 000 r/m (disp-lo),(disp-hi), data-lo,data-hi add reg16/mem16,immed16
	;;             mod 001 r/m (disp-lo),(disp-hi), data-lo,data-hi or  reg16/mem16,immed16
	;; 	           mod 010 r/m (disp-lo),(disp-hi), data-lo,data-hi adc reg16/mem16,immed16
	;; 	           mod 011 r/m (disp-lo),(disp-hi), data-lo,data-hi sbb reg16/mem16,immed16
	;; 	           mod 100 r/m (disp-lo),(disp-hi), data-lo,data-hi and reg16/mem16,immed16
case81:	;1000 0001 mod 101 r/m (disp-lo),(disp-hi), data-lo,data-hi sub reg16/mem16,immed16
	;; 	           mod 110 r/m (disp-lo),(disp-hi), data-lo,data-hi xor reg16/mem16,immed16
	;; 	           mod 111 r/m (disp-lo),(disp-hi), data-lo,data-hi cmp reg16/mem16,immed16
case82:	;1000 0010 mod 000 r/m (disp-lo),(disp-hi), data-8          add reg8/mem8,immed8
	;; 	           mod 001 r/m                                      -   
	;; 	           mod 010 r/m (disp-lo),(disp-hi), data-8          adc reg8/mem8,immed8
	;; 	           mod 011 r/m (disp-lo),(disp-hi), data-8          sbb reg8/mem8,immed8
	;; 			   mod 100 r/m                                      —
	;; 	           mod 101 r/m (disp-lo),(disp-hi), data-8          sub reg8/mem8,immed8
	;; 	           mod 110 r/m                                      —
	;; 	           mod 111 r/m (disp-lo),(disp-hi), data-8          cmp reg8/mem8,immed8
case83:	;1000 0011 mod 000 r/m (disp-lo),(disp-hi), data-SX         add reg16/mem16,immed8
	;; 	           mod 001 r/m                                      —
	;; 	           mod 010 r/m (disp-lo),(disp-hi), data-SX         adc  reg16/mem16,immed8
	;; 	           mod 011 r/m (disp-lo),(disp-hi), data-SX         sbb reg16/mem16,immed8
	;; 	           mod 100 r/m                                      —
	;; 	           mod 101 r/m (disp-lo),(disp-hi), data-SX         sub  reg16/mem16,immed8
	;; 	           mod 110 r/m                                      —
	;; 	           mod 111 r/m (disp-lo),(disp-hi), data-SX         cmp  reg16/mem16,immed8
case8C:	;1000 1100 mod OSR r/m (disp-lo),(disp-hi) mov   reg16/mem16,SEGREG
	    ;;         mod 1 - r/m                     —
case8D:	;1000 1101 mod reg r/m (disp-lo),(disp-hi)   lea   reg16,mem16
case8E:	;1000 1110 mod OSR r/m (disp-lo),(disp-hi)   mov    SEGREG,reg16/mem16
	;; mod 1 - r/m                       —
case8F:	;1000 1111                                   pop   mem16
case90:	;1001 0000                                   nop   (xchg AX,AX)

case9A:	;1001 1010 disp-lo     disp-hi,seg-lo,seg-hi call  far-proc
caseA0:	;1010 0000 addr-lo     addr-hi               mov   AL,mem8
caseA1:	;1010 0001 addr-lo     addr-hi               mov   AX,mem16
caseA2:	;1010 0010 addr-lo     addr-hi               mov   mem8,AL
caseA3:	;1010 0011 addr-lo     addr-hi               mov   mem16,AL
caseA8:	;1010 1000 data-8                            test  AL,immed8
caseA9:	;1010 1001 data-lo     data-hi               test  AX,immed16
caseC0:	;1100 0000 mod 000 r/m data-8  rol     reg8/mem8, immed8
	;;             mod 001 r/m data-8  ror     reg8/mem8, immed8
	;;             mod 010 r/m data-8  rcl     reg8/mem8, immed8
	;;             mod 011 r/m data-8  rcr     reg8/mem8, immed8
	;;             mod 100 r/m data-8  shl/sal reg8/mem8, immed8
	;;             mod 101 r/m data-8  shr     reg8/mem8, immed8
	;;             mod 110 r/m         —
	;;             mod 111 r/m data-8  sar     reg8/mem8, immed8
caseC1:	;1100 0001 mod 000 r/m data-8  rol     reg16/mem16, immed8
	;;             mod 001 r/m data-8  ror     reg16/mem16, immed8
	;;             mod 010 r/m data-8  rcl     reg16/mem16, immed8
	;;             mod 011 r/m data-8  rcr     reg16/mem16, immed8
	;;             mod 100 r/m data-8  shl/sal reg16/mem16, immed8
	;;             mod 101 r/m data-8  shr     reg16/mem16, immed8
	;;             mod 110 r/m         —
	;;             mod 111 r/m data-8 sar reg16/mem16, immed8
caseC2:	;1100 0010 data-lo     data-hi                             ret     immed16 (intrasegment)
caseC3:	;1100 0011                                                 ret     (intrasegment)
caseC4:	;1100 0100 mod reg r/m (disp-lo),(disp-hi)                 les     reg16,mem16
caseC5:	;1100 0101 mod reg r/m (disp-lo),(disp-hi)                 lds     reg16,mem16
caseC6:	;1100 0110 mod 000 r/m (disp-lo),(disp-hi),data-8          mov     mem8,immed8
	;;             mod 001 r/m                                     —
	;; 			   mod 010 r/m                                     —
	;;    		   mod 011 r/m                                     —
	;;             mod 100 r/m                                     —
	;;             mod 101 r/m                                     —
	;;             mod 110 r/m                                     —
caseC7:	;1100 0111 mod 000 r/m (disp-lo),(disp-hi),data-lo,data-hi mov        mem16,immed16
	;;             mod 001 r/m                                     —
	;;             mod 010 r/m                                     —
	;;             mod 011 r/m                                     —
	;;             mod 100 r/m                                     —
	;;             mod 101 r/m                                     —
	;;             mod 110 r/m                                     — 
	;;             mod 111 r/m                                     —
caseCA:	;1100 1010 data-lo     data-hi                             ret     immed16 (intersegment)
caseCB:	;1100 1011                                                 ret     (intersegment)
caseCC:	;1100 1100                                                 int     3
caseD0:	;1101 0000 mod 000 r/m (disp-lo),(disp-hi)                 rol     reg8/mem8,1
	;;             mod 001 r/m (disp-lo),(disp-hi)                 ror     reg8/mem8,1
	;;             mod 010 r/m (disp-lo),(disp-hi)                 rcl     reg8/mem8,1
	;;             mod 011 r/m (disp-lo),(disp-hi)                 rcr     reg8/mem8,1
	;;             mod 100 r/m (disp-lo),(disp-hi)                 sal/shl reg8/mem8,1
	;;             mod 101 r/m (disp-lo),(disp-hi)                 shr     reg8/mem8,1
	;;             —
	;;             mod 110 r/m
	;;             mod 111 r/m (disp-lo),(disp-hi)                 sar     reg8/mem8,1
caseD1:	;1101 0001 mod 000 r/m (disp-lo),(disp-hi) rol           reg16/mem16,1
	;;             mod 001 r/m (disp-lo),(disp-hi) ror           reg16/mem16,1
caseD1:	;1101 0001 mod 010 r/m (disp-lo),(disp-hi) rcl           reg16/mem16,1
	;;             mod 011 r/m (disp-lo),(disp-hi) rcr           reg16/mem16,1
	;;             mod 100 r/m (disp-lo),(disp-hi) sal/shl        reg16/mem16,1
	;;             mod 101 r/m (disp-lo),(disp-hi) shr           reg16/mem16,1
	;;             mod 110 r/m                     —
	;;             mod 111 r/m (disp-lo),(disp-hi) sar           reg16/mem16,1
caseD2:	;1101 0010 mod 000 r/m (disp-lo),(disp-hi) rol           reg8/mem8,CL
	;;             mod 001 r/m (disp-lo),(disp-hi) ror           reg8/mem8,CL
	;;             mod 010 r/m (disp-lo),(disp-hi) rcl           reg8/mem8,CL
	;;             mod 011 r/m (disp-lo),(disp-hi) rcr           reg8/mem8,CL
	;;             mod 100 r/m (disp-lo),(disp-hi) sal/shl       reg8/mem8,CL
	;;             mod 101 r/m (disp-lo),(disp-hi) shr           reg8/mem8,CL
	;;             mod 110 r/m                     —
	;;             mod 111 r/m (disp-lo),(disp-hi) sar           reg8/mem8,CL
caseD3:	;1101 0011 mod 000 r/m (disp-lo),(disp-hi) rol           reg16/mem16,CL
	;;             mod 001 r/m (disp-lo),(disp-hi) ror           reg16/mem16,CL
	;;             mod 010 r/m (disp-lo),(disp-hi) rcl           reg16/mem16,CL
	;;             mod 011 r/m (disp-lo),(disp-hi) rcr           reg16/mem16,CL
	;;             mod 100 r/m (disp-lo),(disp-hi) sal/shl        reg16/mem16,CL
	;;             mod 101 r/m (disp-lo),(disp-hi) shr           reg16/mem16,CL
	;;             mod 110 r/m                     —
	;;             mod 111 r/m (disp-lo),(disp-hi) sar           reg16/mem16,CL
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
caseFE:	;1111 1110 mod 000 r/m (disp-lo),(disp-hi) inc  mem16
   	;;             mod 001 r/m (disp-lo),(disp-hi) dec  mem16
	;;             mod 010 r/m                     —
caseFF:	;1111 1111 mod 000 r/m (disp-lo),(disp-hi) inc  mem16
	;; mod 001 r/m (disp-lo),(disp-hi) dec  mem16
	;; mod 010 r/m (disp-lo),(disp-hi) call reg16/mem16 (intrasegment)
	;; mod 011 r/m (disp-lo),(disp-hi) call mem16 (intersegment)
	;; mod 100 r/m (disp-lo),(disp-hi) jmp  reg16/mem16 (intrasegment)
	;; mod 101 r/m (disp-lo),(disp-hi) jmp  mem16 (intersegment)
	;; mod 110 r/m (disp-lo),(disp-hi) push mem16
	;; mod 111 r/m                     —	



