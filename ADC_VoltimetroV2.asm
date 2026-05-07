; VOLTÍMETRO DIGITAL
; 	Formato: X.XXX

; REGISTRADORES 
;   A, B  – operandos MUL
;   R2    – dígito unidades
;   R3    – dígito décimos
;   R4    – dígito centésimos
;   R5    – dígito milésimos
;   R7    – contador exclusivo do DELAY_DISP

; NÃO UTILIZADO!!
; RAM 
;   20H = cód. 7-seg DISP0 (milésimos)
;   21H = cód. 7-seg DISP1 (centésimos)
;   22H = cód. 7-seg DISP2 (décimos)
;   23H = cód. 7-seg DISP3 (unidades + ponto decimal)
;   Pilha a partir de 51H

; CÁLCULO
;   Tensão = ADC × 5 / 256
;   Dividir por 256 = pegar o byte alto (B) após MUL AB

; NÃO UTILIZADO!
; DELAY_DISP: R7 = #100 
;   6×100 + 3 = 603 µs por display

RD_ADC      EQU  P3.7     	; nível baixo habilita saídas D0–D7
WR_ADC      EQU  P3.6     	; borda de subida inicia conversão
INTR_ADC    EQU  P3.2     	; vai para 0 quando conversão termina

CS_DECODER  EQU  P0.7    	; nível alto habilita o decoder
A0_DECODER  EQU  P3.3     	; bit LSB de seleção do display
A1_DECODER  EQU  P3.4     	; bit MSB de seleção do display

DADOS_ADC    EQU  P2     	; D0–D7 do ADC: leitura do valor convertido
DISPLAY_7SEG EQU  P1      	; segmentos a, b, c, d, e, f, g, dp dos displays

ORG  0000H
    JMP  INICIO

INICIO:
	MOV	SP, #2FH
    MOV  DPTR, #TAB_DISPLAY_7SEG

    ; ADC em repouso
    SETB RD_ADC
    SETB WR_ADC

MAIN_LOOP:

    ; habilita conversão do input para o ADC
    CLR  WR_ADC
    NOP
    NOP
    SETB WR_ADC

    ; Espera ADC estar OK para coletar D0-D7
ESPERA_AND_REFRESH:
    JB   INTR_ADC, ESPERA_AND_REFRESH

    ; Leitura do ADC
    CLR  RD_ADC
    NOP
    NOP
    MOV  A,    DADOS_ADC
    SETB RD_ADC

; CALC_DIGITOS
; Entrada : A = valor ADC (0–255)
; Efeito  : preenche 20H–23H com códigos 7-seg
;   MUL AB com B=#5:  B = unidades
;   MUL AB com B=#10: B = décimos
;   MUL AB com B=#10: B = centésimos
;   MUL AB com B=#10: B = milésimos

CALC_DIGITOS:

    ; UNIDADES
	; cálculo da unidade
    MOV  B,    #5
    MUL  AB                
    MOV  R0,   B

	; conversão para display 7 seg
	MOV  A,    R2          ; DISP3: unidades + ponto decimal
    MOVC A,    @A+DPTR
    ANL  A,    #7FH        ; bit 7 = 0 → acende dp
    MOV  R2,  A
	ACALL REFRESH_UNIDADE

    ; DÉCIMOS
	; cálculo décimo
    MOV  B,    #10
    MUL  AB
    MOV  R3,   B

	; conversão para display 7 seg
	MOV  A,    R3          ; DISP2: décimos
    MOVC A,    @A+DPTR
    MOV  R3,  A
	ACALL REFRESH_DECIMO

    ; CENTÉSIMOS
	; cálculo centésimo
    MOV  B,    #10
    MUL  AB
    MOV  R4,   B

	; conversão para display 7 seg
    MOV  A,    R4          ; DISP1: centésimos
    MOVC A,    @A+DPTR
    MOV  R4,  A
	ACALL REFRESH_CENTESIMO

    ; MILÉSIMOS
	; cálculo milésimo
    MOV  B,    #10
    MUL  AB
    MOV  R5,   B

	; conversão para display 7 seg
    MOV  A,    R5          ; DISP0: milésimos
    MOVC A,    @A+DPTR
    MOV  R5,  A
	ACALL REFRESH_MILESIMO

    SJMP MAIN_LOOP

REFRESH_UNIDADE:
    ; DISP3: unidades, A1=1 A0=1
    CLR CS_DECODER
    SETB A1_DECODER
    SETB A0_DECODER
	MOV  DISPLAY_7SEG, R2
	SETB CS_DECODER

	RET

REFRESH_DECIMO:
    ; DISP2: décimos, A1=1 A0=0
    CLR CS_DECODER
    SETB A1_DECODER
    CLR  A0_DECODER
	MOV  DISPLAY_7SEG, R3
	SETB CS_DECODER

	RET

REFRESH_CENTESIMO:
    ; DISP1: centésimos, A1=0 A0=1
    CLR CS_DECODER
    CLR  A1_DECODER
    SETB A0_DECODER
	MOV  DISPLAY_7SEG, R4
	SETB CS_DECODER

	RET

REFRESH_MILESIMO:
    ; DISP0: milésimos, A1=0 A0=0
    CLR CS_DECODER
    CLR  A1_DECODER
    CLR  A0_DECODER
	MOV  DISPLAY_7SEG, R5
	SETB CS_DECODER

    RET

TAB_DISPLAY_7SEG:
    DB  11000000B          ; '0'
    DB  11111001B          ; '1'
    DB  10100100B          ; '2'
    DB  10110000B          ; '3'
    DB  10011001B          ; '4'
    DB  10010010B          ; '5'
    DB  10000010B          ; '6'
    DB  11111000B          ; '7'
    DB  10000000B          ; '8'
    DB  10010000B          ; '9'

    END
