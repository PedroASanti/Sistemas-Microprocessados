ORG	0000H			;Organizar início do programa
MAIN:
	MOV	C,P1.7		;1us - O registrador recebe o valor do bit P1.7
	CPL	C		;1us - Inverte o valor do registrador C
	MOV	P1.7,C		;2us - o bit P1.7 recebe o valor do registrador
	ACALL	DELAY500MS	;2us - Vai para a sub-rotina DELAY500MS
	AJMP	MAIN		;2us - Retorna para o MAIN
DELAY500MS:
	MOV	R1,#00FAH	;1us - Armazena o valor de 250 no registrador R1
LOOP1:
	MOV	R2,#00F9H	;1us - Armazena o valor de 249 no registrador R2 - 	250 x 1us
	NOP			;1us - No Operation					250 x 1us
	NOP			;							250 x 1us
	NOP			;							250 x 1us
	NOP			;							250 x 1us
LOOP2:
	NOP			;							250 X 249 x 1us = 62250 us
	NOP			;							250 x 249 x 1us = 62250 us
	NOP			;							250 x 249 x 1us = 62250 us
	NOP			;							250 x 249 x 1us = 62250 us
	NOP			;							250 x 249 x 1us = 62250 us
	NOP			;							250 x 249 x 1us = 62250 us

	DJNZ	R2,LOOP2	;2us - Decrementa o valor que está no R2 e retorna para o LOOP2 até que R2 zere		250 x 249 x 2 = 124500 us
	DJNZ	R1,LOOP1	;2us - Decrementa o valor que está no R1 e retorna para o LOOP2 até que R2 zere		250 x 2 = 500 us
	
	MOV	R3,#004FH	;1us - 79 em decimal
AJUSTE:				;É preciso fazer um ajuste de 239 us
	NOP			;79 X 1us
	DJNZ	R3,AJUSTE	;79 x 2us
	NOP			;Mais um ciclo de máquina de atraso para completar os 239 us

	RET			;2us - Retorna para o início do código
END