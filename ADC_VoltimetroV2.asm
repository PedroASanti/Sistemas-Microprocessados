; VOLTÍMETRO DIGITAL – Versão 2
; Formato: X.XXX V

; Nesta versão decidi retirar o armazenamento dos bytes codificados para o display de 7 segmentos nas memórias de programa (RAM) 20H, 21H, 22H e 23H e colocar nos registradores R2, R3, R4 e R5.
; Além disso, mudei a forma de exibição nos displays. Antes o uC coletava o valor do ADC e colocava em A e com esse valor calculava os números da unidade, do décimo, do centésimo e do milésimo e, então,
; exibia eles com ajuda de um delay para cada display. Agora o uC calcula o número, exibe ele em seu respectivo display e depois calcula o próximo para exibir novamente em outro display, sendo este intervalo de tempo do cálculo o delay
; para exibir de um display para o outro

; REGISTRADORES
;   A, B  – operandos MUL e conversão 7-seg
;   R2    – código 7-seg unidade   (com ponto decimal)
;   R3    – código 7-seg décimo
;   R4    – código 7-seg centésimo
;   R5    – código 7-seg milésimo
;   R7    – guarda a fração temporariamente entre MUL e MOVC

; CÁLCULO
;   Tensão = ADC × 5 / 256
;   Após MUL AB: B = dígito (byte alto = divisão implícita por 256)
;   A = fração restante (passa para o próximo passo)

; EXIBIÇÃO
;   Para cada dígito:
;     1. Calcula via MUL AB
;     2. Salva fração em R7
;     3. Converte dígito via MOVC
;     4. Armazena código em Rn
;     5. Chama REFRESH_* (desliga decoder, configura A0/A1, liga decoder)
;     6. Recupera fração de R7 para o próximo MUL
;   O tempo gasto nos passos 2–5 funciona como delay entre displays

RD_ADC      EQU  P3.7     ; nível baixo habilita saídas D0–D7
WR_ADC      EQU  P3.6     ; borda de subida inicia conversão
INTR_ADC    EQU  P3.2     ; vai para 0 quando conversão termina

CS_DECODER  EQU  P0.7     ; nível alto habilita o decoder
A0_DECODER  EQU  P3.3     ; bit LSB de seleção do display
A1_DECODER  EQU  P3.4     ; bit MSB de seleção do display

DADOS_ADC    EQU  P2      ; D0–D7 do ADC: leitura do valor convertido
DISPLAY_7SEG EQU  P1      ; segmentos a, b, c, d, e, f, g, dp dos displays

    ORG  0000H
    JMP  INICIO

    ORG  0030H

INICIO:
    MOV  SP,   #4FH
    MOV  DPTR, #TAB_DISPLAY_7SEG

    ; ADC em repouso
    SETB RD_ADC
    SETB WR_ADC

    ; Decoder desabilitado até ter valor válido
    CLR  CS_DECODER

MAIN_LOOP:

    ; Dispara conversão ADC
    CLR  WR_ADC
    NOP
    NOP
    SETB WR_ADC

    ; Aguarda INTR = 0 (conversão completa)
ESPERA_INTR:
    JB   INTR_ADC, ESPERA_INTR

    ; Leitura do ADC
    CLR  RD_ADC
    NOP
    NOP
    MOV  A,    DADOS_ADC
    SETB RD_ADC

    ; CALC_DIGITOS + exibição intercalada

    ; UNIDADES
    MOV  B,    #5
    MUL  AB                ; B = unidades (0–4), A = fração
    MOV  R7,   A           ; salva fração
    MOV  A,    B           ; A = dígito
    MOVC A,    @A+DPTR     ; converte para código 7-seg
    ANL  A,    #7FH        ; acende ponto decimal
    MOV  R2,   A           ; R2 = código pronto
    ACALL REFRESH_UNIDADE
    MOV  A,    R7          ; recupera fração

    ; DÉCIMOS
    MOV  B,    #10
    MUL  AB                ; B = décimos (0–9), A = fração
    MOV  R7,   A
    MOV  A,    B
    MOVC A,    @A+DPTR
    MOV  R3,   A           ; R3 = código pronto
    ACALL REFRESH_DECIMO
    MOV  A,    R7

    ; CENTÉSIMOS
    MOV  B,    #10
    MUL  AB                ; B = centésimos (0–9), A = fração
    MOV  R7,   A
    MOV  A,    B
    MOVC A,    @A+DPTR
    MOV  R4,   A           ; R4 = código pronto
    ACALL REFRESH_CENTESIMO
    MOV  A,    R7

    ; MILÉSIMOS (sem salvar fração — último dígito)
    MOV  B,    #10
    MUL  AB                ; B = milésimos (0–9)
    MOV  A,    B
    MOVC A,    @A+DPTR
    MOV  R5,   A           ; R5 = código pronto
    ACALL REFRESH_MILESIMO

    SJMP MAIN_LOOP

REFRESH_UNIDADE:
    CLR  CS_DECODER        ; desabilita decoder (apaga display atual)
    SETB A1_DECODER        ; A1 = 1
    SETB A0_DECODER        ; A0 = 1  →  DISP3
    MOV  DISPLAY_7SEG, R2  ; segmentos das unidades + dp
    SETB CS_DECODER        ; habilita decoder → DISP3 acende
    RET

REFRESH_DECIMO:
    CLR  CS_DECODER
    SETB A1_DECODER        ; A1 = 1
    CLR  A0_DECODER        ; A0 = 0  →  DISP2
    MOV  DISPLAY_7SEG, R3
    SETB CS_DECODER
    RET

REFRESH_CENTESIMO:
    CLR  CS_DECODER
    CLR  A1_DECODER        ; A1 = 0
    SETB A0_DECODER        ; A0 = 1  →  DISP1
    MOV  DISPLAY_7SEG, R4
    SETB CS_DECODER
    RET

REFRESH_MILESIMO:
    CLR  CS_DECODER
    CLR  A1_DECODER        ; A1 = 0
    CLR  A0_DECODER        ; A0 = 0  →  DISP0
    MOV  DISPLAY_7SEG, R5
    SETB CS_DECODER
    RET

; TAB_DISPLAY_7SEG – ânodo comum

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
