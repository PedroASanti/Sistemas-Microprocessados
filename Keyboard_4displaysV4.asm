ORG 0000H
    JMP INICIO

ORG 0030H

DISPLAY7 EQU P1
CONTROL7 EQU P2

INICIO:
    ANL CONTROL7, #0F0H		; apaga os 4 displays com o AND, zerando a parte baixa

    MOV DPTR, #TAB_SEG7		; DPTR aponta para a tabela que converte os caracteres em display de 7 segmentos

; os endereços 20H a 23H vão ser usados para armazenar os valores de cada display para serem usados na subrotina REFRESH para os displays não apagarem
    MOV 20H, #0			; memória display 0
    MOV 21H, #0			; memória display 1
    MOV 22H, #0			; memória display 2
    MOV 23H, #0			; memória display 3
    MOV 24H, #0          	; backup do DISPLAY7

    ; Ativa display 3
    MOV A, CONTROL7
    ORL A, #00001000B
    MOV CONTROL7, A		; aqui o display que deve ser ligado na vez, é habilitado

    MOV DISPLAY7, #0		; zera o P1

; SCAN: espera uma tecla ser pressionada
; OBS.: como aqui é um lugar no código que pode ficar parado muito tempo, coloquei para chamar a subrotina REFRESH cada vez que nenhuma tecla é apertada para atualizar os displays que estavam ligados

SCAN:
    ACALL REFRESH
SCAN_LINHA1:
    CLR P0.3			; zera linha 1, caso alguma das colunas (P0.6, .5, .4, .7) receba este zero, é porque uma tecla foi pressionada e fechou o contato
    
    JNB P0.7, SCAN1_A
    JNB P0.6, SCAN1_1
    JNB P0.5, SCAN1_2
    JNB P0.4, SCAN1_3
    SETB P0.3
SCAN_LINHA2:
    CLR P0.2
    JNB P0.7, SCAN2_B
    JNB P0.6, SCAN2_4
    JNB P0.5, SCAN2_5
    JNB P0.4, SCAN2_6
    SETB P0.2
SCAN_LINHA3:
    CLR P0.1
    JNB P0.7, SCAN3_C
    JNB P0.6, SCAN3_7
    JNB P0.5, SCAN3_8
    JNB P0.4, SCAN3_9
    SETB P0.1
SCAN_LINHA4:
    CLR P0.0
    JNB P0.7, SCAN4_D
    JNB P0.6, SCAN4_AST
    JNB P0.5, SCAN4_0
    JNB P0.4, SCAN4_HAS
    SETB P0.0
    SJMP SCAN

; Subrotinas intermediárias — próximas ao SCAN, alcançáveis pelo JNB
; o JNB consegue saltar o código 1 byte de distancia (-128 a 127) e se pulasse direto para as subrotinas TECLA_X em alguns casos ele excedia estas 127 posições

SCAN1_A:
	LJMP TECLA_A
SCAN1_1:
	LJMP TECLA_1
SCAN1_2:
	LJMP TECLA_2
SCAN1_3:
	LJMP TECLA_3
SCAN2_B:
	LJMP TECLA_B
SCAN2_4:
	LJMP TECLA_4
SCAN2_5:
	LJMP TECLA_5
SCAN2_6:
	LJMP TECLA_6
SCAN3_C:
	LJMP TECLA_C
SCAN3_7:
	LJMP TECLA_7
SCAN3_8:
	LJMP TECLA_8
SCAN3_9:
	LJMP TECLA_9
SCAN4_D:
	LJMP TECLA_D
SCAN4_AST:
	LJMP TECLA_AST
SCAN4_0:
	LJMP TECLA_0
SCAN4_HAS:
	LJMP TECLA_HAS

TECLA_A:
	MOV R2, #12		; posição na tabela 7 segmentos
	MOV R3, #3		; bit da linha da tecla pressionada. Usado para dar um SETB nessa linha após a tecla ser solta
	MOV R4, #10000000B	; Máscara da coluna da tecla apertada. Utilizada para caso o usuário pressione uma tecla e depois pressione outra da mesma linha
	LJMP ESPERA_SOLTAR
TECLA_1:
	MOV R2, #1
	MOV R3, #3
	MOV R4, #01000000B
	LJMP ESPERA_SOLTAR
TECLA_2:
	MOV R2, #2
	MOV R3, #3
	MOV R4, #00100000B
	LJMP ESPERA_SOLTAR
TECLA_3:
	MOV R2, #3
	MOV R3, #3
	MOV R4, #00010000B
	LJMP ESPERA_SOLTAR
TECLA_B:
	MOV R2, #13
	MOV R3, #2
	MOV R4, #10000000B
	LJMP ESPERA_SOLTAR
TECLA_4:
	MOV R2, #4
	MOV R3, #2
	MOV R4, #01000000B
	LJMP ESPERA_SOLTAR
TECLA_5:
	MOV R2, #5
	MOV R3, #2
	MOV R4, #00100000B
	LJMP ESPERA_SOLTAR
TECLA_6:
	MOV R2, #6
	MOV R3, #2
	MOV R4, #00010000B
	LJMP ESPERA_SOLTAR
TECLA_C:
	MOV R2, #14
	MOV R3, #1
	MOV R4, #10000000B
	LJMP ESPERA_SOLTAR
TECLA_7:
	MOV R2, #7
	MOV R3, #1
	MOV R4, #01000000B
	LJMP ESPERA_SOLTAR
TECLA_8:
	MOV R2, #8
	MOV R3, #1
	MOV R4, #00100000B
	LJMP ESPERA_SOLTAR
TECLA_9:
	MOV R2, #9
	MOV R3, #1
	MOV R4, #00010000B
	LJMP ESPERA_SOLTAR
TECLA_D:
	MOV R2, #15
	MOV R3, #0
	MOV R4, #10000000B
	LJMP ESPERA_SOLTAR
TECLA_AST:
	MOV R2, #10
	MOV R3, #0
	MOV R4, #01000000B
	LJMP ESPERA_SOLTAR
TECLA_0:
	MOV R2, #0
	MOV R3, #0
	MOV R4, #00100000B
	LJMP ESPERA_SOLTAR
TECLA_HAS:
	MOV R2, #11
	MOV R3, #0
	MOV R4, #00010000B
	LJMP ESPERA_SOLTAR

; REFRESH é chamado aqui pelo mesmo motivo da parte do SCAN, código pode ficar preso aqui porum tempo

ESPERA_SOLTAR:
    ACALL REFRESH

    MOV A, P0
    ANL A, R4             ; set no bit da coluna da tecla pressionada
    CJNE A, 04H, ESPERA_SOLTAR  ; 04H = endereço direto de R4 no banco 0. Aqui o A é comparado com o R4 e segue o código quando as colunas de P0 irem pra HIGH

    ; Restaura linha correspondente após confirmar tecla solta
    MOV A, R3
    CJNE A, #3, ES_L2
    SETB P0.3
    LJMP EXIBE
ES_L2:
    CJNE A, #2, ES_L3
    SETB P0.2
    LJMP EXIBE
ES_L3:
    CJNE A, #1, ES_L4
    SETB P0.1
    LJMP EXIBE
ES_L4:
    SETB P0.0
    LJMP EXIBE

; EXIBE: busca código, grava em um dos endereços 20H a 23H e exibe

EXIBE:
    MOV A, R2			; A recebe o índice da tabela
    MOVC A, @A+DPTR		; A recebe o valor da tabela 7 segm
    MOV DISPLAY7, A       ; exibe no display
    MOV 24H, A            ; backup do estado atual de DISPLAY7

    ; Grava o código na posição RAM correspondente ao display ativo
    ; Usa R1 como ponteiro (8051 só permite @R0 e @R1)
    JB CONTROL7.3, GRAVA_23
    JB CONTROL7.2, GRAVA_22
    JB CONTROL7.1, GRAVA_21
    JB CONTROL7.0, GRAVA_20
    SJMP AVANCA_DISPLAY   ; fallback

GRAVA_23:
	MOV R1, #23H
	MOV @R1, A
	SJMP AVANCA_DISPLAY
GRAVA_22:
	MOV R1, #22H
	MOV @R1, A
	SJMP AVANCA_DISPLAY
GRAVA_21:
	MOV R1, #21H
	MOV @R1, A
	SJMP AVANCA_DISPLAY
GRAVA_20:
	MOV R1, #20H
	MOV @R1, A
	SJMP AVANCA_DISPLAY

; ─────────────────────────────────────────────
; AVANCA_DISPLAY: rotaciona bit ativo
; ─────────────────────────────────────────────
AVANCA_DISPLAY:
    MOV DISPLAY7, #0
    MOV 24H, #0           ; atualiza backup também

    MOV A, CONTROL7
    ANL A, #00001111B

    RRC A
    JNC AVANCA_OK
    MOV A, #00001000B
AVANCA_OK:
    MOV B, A
    MOV A, CONTROL7
    ANL A, #0F0H
    ORL A, B
    MOV CONTROL7, A

    LJMP SCAN

; ─────────────────────────────────────────────
; REFRESH: exibe os 4 displays e RESTAURA o estado original
; ─────────────────────────────────────────────
REFRESH:
    ; Salva estado atual de CONTROL7 em R7
    MOV A, CONTROL7
    MOV R7, A

    ; Display 3
    ANL CONTROL7, #0F0H
    MOV A, 23H
    MOV DISPLAY7, A
    MOV A, CONTROL7
    ORL A, #00001000B
    MOV CONTROL7, A

    ; Display 2
    ANL CONTROL7, #0F0H
    MOV A, 22H
    MOV DISPLAY7, A
    MOV A, CONTROL7
    ORL A, #00000100B
    MOV CONTROL7, A

    ; Display 1
    ANL CONTROL7, #0F0H
    MOV A, 21H
    MOV DISPLAY7, A
    MOV A, CONTROL7
    ORL A, #00000010B
    MOV CONTROL7, A

    ; Display 0
    ANL CONTROL7, #0F0H
    MOV A, 20H
    MOV DISPLAY7, A
    MOV A, CONTROL7
    ORL A, #00000001B
    MOV CONTROL7, A

    ; Restaura CONTROL7 e DISPLAY7 ao estado original
    ANL CONTROL7, #0F0H   ; apaga antes de restaurar
    MOV A, 24H
    MOV DISPLAY7, A       ; restaura DISPLAY7
    MOV A, R7
    MOV CONTROL7, A       ; restaura CONTROL7

    RET

; ─────────────────────────────────────────────
TAB_SEG7:
    DB 00111111B, 00000110B, 01011011B, 01001111B
    DB 01100110B, 01101101B, 01111101B, 00000111B
    DB 01111111B, 01101111B, 10000000B, 01110110B
    DB 01110111B, 01111100B, 00111001B, 01011110B

END