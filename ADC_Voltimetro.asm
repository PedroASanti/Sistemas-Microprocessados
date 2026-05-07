; VOLTÍMETRO DIGITAL
; 	Formato: X.XXX

; REGISTRADORES 
;   A, B  – operandos MUL
;   R0    – dígito unidades
;   R1    – dígito décimos
;   R2    – dígito centésimos
;   R3    – dígito milésimos
;   R7    – contador exclusivo do DELAY_DISP

; RAM 
;   20H = cód. 7-seg DISP0 (milésimos)
;   21H = cód. 7-seg DISP1 (centésimos)
;   22H = cód. 7-seg DISP2 (décimos)
;   23H = cód. 7-seg DISP3 (unidades + ponto decimal)
;   Pilha a partir de 51H

; CÁLCULO
;   Tensão = ADC × 5 / 256
;   Dividir por 256 = pegar o byte alto (B) após MUL AB

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
    MOV  SP,   #2FH
    MOV  DPTR, #TAB_DISPLAY_7SEG

    ; ADC em repouso
    SETB RD_ADC
    SETB WR_ADC
    
    SETB CS_DECODER

    ; Inicializa RAM dos displays com 0FFH (segmentos apagados)
    MOV  20H,  #0FFH
    MOV  21H,  #0FFH
    MOV  22H,  #0FFH
    MOV  23H,  #0FFH

MAIN_LOOP:

    ; habilita conversão do input para o ADC
    CLR  WR_ADC
    NOP
    NOP
    SETB WR_ADC

    ; Mantém displays atualizados até o fim da conversão
ESPERA_AND_REFRESH:
    ACALL REFRESH
    JB   INTR_ADC, ESPERA_AND_REFRESH

    ; Leitura do ADC
    CLR  RD_ADC
    NOP
    NOP
    MOV  A,    DADOS_ADC
    SETB RD_ADC

    ACALL CALC_DIGITOS

    SJMP MAIN_LOOP

; CALC_DIGITOS
; Entrada : A = valor ADC (0–255)
; Efeito  : preenche 20H–23H com códigos 7-seg
;   MUL AB com B=#5:  B = unidades
;   MUL AB com B=#10: B = décimos
;   MUL AB com B=#10: B = centésimos
;   MUL AB com B=#10: B = milésimos

CALC_DIGITOS:

    ; UNIDADES
    MOV  B,    #5
    MUL  AB                
    MOV  R0,   B

    ; DÉCIMOS
    MOV  B,    #10
    MUL  AB
    MOV  R1,   B

    ; CENTÉSIMOS
    MOV  B,    #10
    MUL  AB
    MOV  R2,   B

    ; MILÉSIMOS
    MOV  B,    #10
    MUL  AB
    MOV  R3,   B

    ; Converte dígitos em códigos 7-seg e grava na RAM

    MOV  A,    R0          ; DISP3: unidades + ponto decimal
    MOVC A,    @A+DPTR
    ANL  A,    #7FH        ; bit 7 = 0 → acende dp
    MOV  23H,  A

    MOV  A,    R1          ; DISP2: décimos
    MOVC A,    @A+DPTR
    MOV  22H,  A

    MOV  A,    R2          ; DISP1: centésimos
    MOVC A,    @A+DPTR
    MOV  21H,  A

    MOV  A,    R3          ; DISP0: milésimos
    MOVC A,    @A+DPTR
    MOV  20H,  A

    RET

; REFRESH – Multiplex dos 4 displays

; Por display:
;   1. DISPLAY_7SEG = #0FFH (apaga display antes de atualizar)
;   2. Atualiza A1/A0
;   3. acende dígito correto
;   4. DELAY_DISP

REFRESH:

    ; DISP3: unidades, A1=1 A0=1
    MOV  DISPLAY_7SEG, #0FFH
    SETB A1_DECODER
    SETB A0_DECODER
    MOV  DISPLAY_7SEG, 23H
    ACALL DELAY_DISP

    ; DISP2: décimos, A1=1 A0=0
    MOV  DISPLAY_7SEG, #0FFH
    SETB A1_DECODER
    CLR  A0_DECODER
    MOV  DISPLAY_7SEG, 22H
    ACALL DELAY_DISP

    ; DISP1: centésimos, A1=0 A0=1
    MOV  DISPLAY_7SEG, #0FFH
    CLR  A1_DECODER
    SETB A0_DECODER
    MOV  DISPLAY_7SEG, 21H
    ACALL DELAY_DISP

    ; DISP0: milésimos, A1=0 A0=0
    MOV  DISPLAY_7SEG, #0FFH
    CLR  A1_DECODER
    CLR  A0_DECODER
    MOV  DISPLAY_7SEG, 20H
    ACALL DELAY_DISP

    RET

DELAY_DISP:
    MOV  R7,   #100
LOOP_DISPLAY:
    NOP
    NOP
    NOP
    NOP
    DJNZ R7,   LOOP_DISPLAY
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
