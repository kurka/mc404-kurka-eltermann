case80: ;1000 0000         mod 000 r/m (disp-lo),(disp-hi), data-8          add reg8/mem8,immed8
	;;                 mod 001 r/m (disp-lo),(disp-hi), data-8          or  reg8/mem8,immed8 
	;; 	           mod 010 r/m (disp-lo),(disp-hi), data-8          adc reg8/mem8,immed8
	;; 	           mod 011 r/m (disp-lo),(disp-hi), data-8          sbb reg8/mem8,immed8
	;; 	           mod 100 r/m (disp-lo),(disp-hi), data-8          and reg8/mem8,immed8
	;; 	           mod 101 r/m (disp-lo),(disp-hi), data-8          sub reg8/mem8,immed8
	;; 	           mod 110 r/m (disp-lo),(disp-hi), data-8          xor reg8/mem8,immed8
	;; 	           mod 111 r/m (disp-lo),(disp-hi), data-8          cmp reg8/mem8,immed8
case81:	;1000 0001         mod 000 r/m (disp-lo),(disp-hi), data-lo,data-hi add reg16/mem16,immed16
	;;                 mod 001 r/m (disp-lo),(disp-hi), data-lo,data-hi or  reg16/mem16,immed16
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
case8E:	;1000 1110 mod OSR r/m (disp-lo),(disp-hi)   mov    SEGREG,reg16/mem16
	;; mod 1 - r/m                       —
case90:	;1001 0000                                   nop   (xchg AX,AX)
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
	;; 	       mod 010 r/m                                     —
	;;    	       mod 011 r/m                                     —
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



