; ------------------------------------------------------------------------------
;                         Identificación del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripción del programa: Sistema de semáforos para controlar 3 vías. 
    
; Hardware: 3 push buttons en el PB, 4 pares de displays multiplexados en el PC
;           con los pines de control en el PD. Asimismo, se incluyen 8 LEDs en 
;           el PA y 3 LEDs en el PE. 
    
; Creado: 13/03
; Última modificación: 
;-------------------------------------------------------------------------------    
;-------------------------------------------------------------------------------  

PROCESSOR 16F887
#include <xc.inc>
    
;CONFIGURATION WORD 1
 CONFIG FOSC=INTRC_NOCLKOUT // Oscillador interno I/O RA6
 CONFIG WDTE=OFF            // WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=OFF           // PWRT enabled (espera de 72ms)
 CONFIG MCLRE=OFF           // El pin de MCLR se utiliza como I/O
 CONFIG CP=OFF              // Sin protección de código
 CONFIG CPD=OFF             // Sin protección de datos

 CONFIG BOREN=OFF           // No reinicia cuándo v de alimentación baja de 4v
 CONFIG IESO=OFF            // Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF           // Cambio de reloj externo a interno en caso falla
 CONFIG LVP=OFF              // Progra en bajo voltaje permitido
 
;CONFIGURATION WORD 2
 CONFIG WRT=OFF             // Protección de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;VARIABLES A UTILIZAR
 PSECT udata_bank0       ; common memory             
   W_TEMP:    DS 1       ; Variable temporal
   STAT_TEMP: DS 1       ; Variable temporal
   FLAG:      DS 1       ; Variable para los botones
   FLAG1:     DS 1  
   FMODO:     DS 1       ; Variable para los modos
   DISP:      DS 1       ; Flag de los DISPLAYS
   TIEMPO:    DS 1       ; Variable queee cuenta los ciclos del TMR0
   COLOR:     DS 1       ; Flag para los colores del semáforo
   TURNO:     DS 1 
   COUNT2:    DS 1
   TIEMPO1:   DS 1       ; Variable para el tiempo
   Bin:       DS 1
   TIEMPO2:   DS 1       ; Variable para el tiempo VÍA 2
   Bin2:      DS 1
   TIEMPO3:   DS 1       ; Variable para el tiempo VÍA 3
   Bin3:      DS 1
   TIEMPO4:   DS 1       ; Variable para el tiempo INDICADOR DE VÍA
   Bin4:      DS 1
    
   TIEMPOO:   DS 1 
   TIEMPO11:  DS 1
   TIEMPO22:  DS 1
   TIEMPO33:  DS 1
   TEMP_TIEMPO1: DS 1
   TEMP_TIEMPO2: DS 1
   TEMP_TIEMPO3: DS 1  
    
   UN1:       DS 1       ; Variable unidades DISPLAY1
   DEC1:      DS 1       ; Variable decenas DISPLAY1
   UN2:       DS 1       ; Variable unidades DISPLAY2
   DEC2:      DS 1       ; Variable decenas DISPLAY2
   UN3:       DS 1       ; Variable unidades DISPLAY3
   DEC3:      DS 1       ; Variable decenas DISPLAY3
   UN4:       DS 1       ; Variable unidades DISPLAY4
   DEC4:      DS 1       ; Variable decenas DISPLAY4
   DIVISOR:   DS 2       ; Variables con los valores a mostrar
   DIVISOR2:  DS 2
   DIVISOR3:  DS 2
   DIVISOR4:  DS 2 
    
;_______________________________________________________________________________
;                          V E C T O R   R E S E T  
;_______________________________________________________________________________   
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
 
 ORG 00h               ; Posición 0000h para el reset
 resetVec:PAGESEL main
    goto main	
;_______________________________________________________________________________
;                        V E C T O R   I N T E R R U P T 
;_______________________________________________________________________________
 ORG 004h              ; Posición 004 para la interrupción
 
PUSH: 
   BCF   INTCON, 7      ; Desact. general interrupt (evitar interr. simultaneas)
   MOVWF W_TEMP         ; Guardar lo que se encuentra en w
   SWAPF STATUS, W      ; Guardar stat. a W sin MOVF (no afectar FLAGS de stat.)
   MOVWF STAT_TEMP      ; Guardar lo de W en variable temporal
     
ISR:                    ; (Interrpt.) chequear que la bandera está encendida
   BTFSC INTCON, 0      ; RBIF PB change interrupt flag (Ver si cambió estado)
   CALL  Button
   BTFSC INTCON, 2      ; Testear bandera del TOIF (overflow del TMR0)
   CALL  Var_regresiva
   CALL  DISPLAY1
   BTFSC INTCON, 2      ; Testear bandera del TOIF
   CALL  Var_regresiva2
   BTFSC PIR1, 1        ; Flag del Match de TMR2 con PR2
   CALL  ACC_LED
       
POP:  
   SWAPF STAT_TEMP, W   ; Regresando el valor al original
   MOVWF STATUS         ; Regresarlo a STATUS
   SWAPF W_TEMP, F      ; darle vuelta a los nibbles de Wtemp
   SWAPF W_TEMP, W      ; Regresamos al orden original y guardamos en w
   RETFIE               ; Regresar de la interrupción (incluye reactiv. del GIE) 	
   
;_______________________________________________________________________________
;                          S U B R U T I N A 
;                    V E C T O R   I N T E R R U P T 
;_______________________________________________________________________________
    
Button: 
    BCF   STATUS, 0     ; Limpiar bandera de carry
    BTFSS PORTB, 0      ; Revisar MODO (1er pin del PORTB)
    BSF   FLAG,  0      ; Setear FLAG
    BTFSS PORTB, 1      ; Revisar ARRIBA (2do pin del PORTB)
    BSF   FLAG,  1      ; Setear FLAG
    BTFSS PORTB, 2      ; Revisar ABAJO (3er pin del PORTB)
    BSF   FLAG,  2      ; Setear FLAG
    BCF   INTCON, 0     ; Limpiar FLAG RBIF
    RETURN 

;----------------------------- D I S P L A Y ----------------------------------
   
PSECT code, delta=2, abs ; A partir de acá es código
ORG 0100h                ;posición para el código
 
Tabla:
    CLRF   PCLATH 
    BSF    PCLATH, 0     ; Limpiar program counter, 0100h
    ADDWF  PCL, 1        ; retlw regresa un valor de W cargado
    RETLW  00111111B     ; 0
    RETLW  00000110B     ; 1
    RETLW  01011011B     ; 2
    RETLW  01001111B     ; 3
    RETLW  01100110B     ; 4
    RETLW  01101101B     ; 5
    RETLW  01111101B     ; 6
    RETLW  00000111B     ; 7
    RETLW  01111111B     ; 8
    RETLW  01100111B     ; 9
;_______________________________________________________________________________
;                         C O N F I G U R A C I O N E S 
;_______________________________________________________________________________
    
config_pines:
    banksel ANSEL          ; Ir al registro donde está ANSEL
    CLRF    ANSEL          ; pines digitales
    CLRF    ANSELH         ; Puerto B digital  
         
    banksel TRISA          ; Ir al banco en donde está TRISA
    BSF     TRISB, 0       ; DECREMENTO
    BSF     TRISB, 1       ; INCREMENTO
    BSF     TRISB, 2       ; MODO
    BCF     TRISB, 3       ; Pines de output
    BCF     TRISB, 4
    BCF     TRISB, 5
    BCF     TRISB, 6
    BCF     TRISB, 7
    CLRF    TRISA          ; Puertos = outputs
    CLRF    TRISC
    CLRF    TRISD
    CLRF    TRISE
    RETURN
    
weak_PU:
    BCF     OPTION_REG, 7   ; Desabilitar el RBPU para utilizar pull up en dos p
    MOVLW   00000111B       ; Habilitar lo del IOCB en pines RB0, RB1 Y RB2
    MOVWF   IOCB            ; Interrupt on change
    MOVWF   WPUB            ; Habilitar pull ups
    RETURN
    
    Inicializar:
    banksel PORTA           ; Ir al banco donde está PORTA
    CLRF    PORTA           ; Inicializar los puertos
    CLRF    PORTB           
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    
    CLRF    W_TEMP          ; Inicializar variables a utilizar
    CLRF    STAT_TEMP
    CLRF    FLAG
    CLRF    TIEMPO
    CLRF    Bin
    CLRF    UN1
    CLRF    DEC1
    BSF     DISP, 0
    BCF     DISP, 1
    CLRF    DIVISOR
    CLRF    COLOR
    CLRF    FMODO            ; Inicia en el primer modo
    MOVLW   00000001B        ; Encender VÍA 1
    MOVWF   TURNO
    
    MOVLW   10               ; Inicializar semáforos tiempo con 10 segundos
    MOVWF   TEMP_TIEMPO1
    MOVWF   TEMP_TIEMPO2
    MOVWF   TEMP_TIEMPO3
    
    MOVWF   TIEMPO1
    MOVWF   TIEMPO2
    MOVWF   TIEMPO3
    CLRF    TIEMPO4
    MOVF    TIEMPO1
    MOVF    TIEMPO2, W
    ADDWF   TIEMPO3          ; TIEMPO de la 3era vía es VÍA1 + VÍA 2
    
    banksel PORTA            ; Inicializar semáforos (LEDS)
    BSF     PORTB, 3         ; Contador de LEDS en 1
    BCF     PORTB, 4
    BCF     PORTB, 5
    MOVLW   00100100B	     ; Primeros dos semáforos
    MOVWF   PORTA
    MOVLW   0001B            ; Tercer semáforo
    MOVLW   PORTE
    RETURN
    
Interrupciones:
    banksel INTCON           ; Configuraciones para TMR0
    BCF     INTCON, 0        ; RBIF Limpiar la bandera de CHANGE INTERRUPT
    BCF     INTCON, 2        ; T0IF Limpiar la bandera del TMR0
    BSF     INTCON, 3        ; RBIE Encender interrupción PORTB CHANGE
    BSF     INTCON, 5        ; T0IE Encender interrupción de OVERFLOW TMR0 
    BSF     INTCON, 6        ; PEIE Encender interrupción periférica
    BSF     INTCON, 7        ; GIE Encender interrupción de global
    
    banksel OPTION_REG       ; Configuraciones para TMR2
    BSF     PIE1, 1          ; TMR1IE Encender interrupción de OVERFLOW TMR2
    banksel TMR0
    BSF     T2CON, 2         ; Encender el timer2
    BCF     PIR1, 1          ; TMR2IF TIMER2 to PR2 Interrupt Flag
    BCF     STATUS, 2        ; Limpiar bandera de Zero
    RETURN

;--------------- E C U A C I Ó N     T E M P O R I Z A D O R -------------------
;              Temporización : 4*TOSC*TMR0*Prescaler (predivisor)
    
PRE0:
    BCF     PSA             ; Prescaler se le asigna al módulo TMR0
    CLRWDT                  ; Clear watch dog y prescalador
    banksel OPTION_REG      ; Ir al banco donde está Op. reg
    MOVLW   11010000B       ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W   ; Prescaler bit
    IORLW   00000100B       ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    RETURN

timer0: 
    banksel TMR0            ; Ir al banco de TMR0
    MOVLW   131             ; TMR0 = 125
    MOVF    TMR0            ; Moverlo a TMR0
    BCF     INTCON, 2       ; Bandera de overflow (viene con v desconocido)
    RETURN 
 
PRE2:
    banksel T2CON
    MOVLW   01001001B       ; Postscaler de 10  y prescaler de 4
    MOVWF   T2CON
    CALL    timer2
    banksel TMR0
    BCF     PIR1, 1         ; Limpiar bandera del TMR2
    RETURN
    
timer2:
    banksel OPTION_REG
    MOVLW   50              ; Valor inicial del registro del TMR2
    MOVWF   PR2             ; Obtener un TMR2IF de 2ms
    RETURN    
        
main: 
    banksel OSCCON
    BSF     SCS             ; Utilizar oscilador interno
    CALL    config_pines
    CALL    weak_PU
    CALL    Interrupciones
    CALL    Inicializar
    CALL    PRE0
    CALL    timer0          ; Inicializar el timer
    CALL    PRE2
    CALL    timer2
;_______________________________________________________________________________
;                                L O O P 
;_______________________________________________________________________________
    
 Loop:
    BTFSC   FLAG, 0       ; Testear si el botón de modo fue presionado
    CALL    MODOS
    CALL    DECC          ; Decenas primer semáforo
    CALL    UNN           ; Unidades primer semáforo  
    CALL    DECC2         ; Decenas segundo semáforo
    CALL    UNN2          ; Unidades segundo semáforo
    CALL    DECC3         ; Decenas tercer semáforo
    CALL    UNN3          ; Unidades tercer semáforo
    CALL    DECC4         ; Decenas Indicador de VÍA
    CALL    UNN4          ; Unidades Indicador de VÍA 
    
    CALL    DISPLAYS1   
    BTFSC   TURNO,    0   ; Flag de la primera VÍA
    CALL    SEMAFORO1	
    BTFSC   TURNO,    1   ; Flag de la segunda VÍA
    CALL    SEMAFORO2				
    BTFSC   TURNO,    2   ; Flag de la tercera VÍA
    CALL    SEMAFORO3		
    CALL    T1		  ; Centello VÍA 1
    CALL    T2		  ; Centello VÍA 2
    CALL    T3		  ; Centello VÍA 3
    goto    Loop
;_______________________________________________________________________________
;                          S U B R U T I N A S 
;_______________________________________________________________________________
        
 MODOS: 
    CALL   MODO1
    INCF   FMODO         ; Subrutina para identificar que modo fue seleccionado
    MOVLW  1
    XORWF  FMODO, F      ; Si es 1 nos vamos al modo 2
    BTFSC  STATUS, 2     ; Si zero = 1 hacer sig. instr.
    CALL   MODO2
    
    MOVLW  2
    XORWF  FMODO, F      ; Si es 1 nos vamos al modo 2
    BTFSC  STATUS, 2     ; Si zero = 1 hacer sig. instr.
    CALL   MODO3
    
    MOVLW  3
    XORWF  FMODO, F      ; Si es 1 nos vamos al modo 2
    BTFSC  STATUS, 2     ; Si zero = 1 hacer sig. instr.
    CALL   MODO4
    
    MOVLW  4
    XORWF  FMODO, F      ; Si es 1 nos vamos al modo 2
    BTFSC  STATUS, 2     ; Si zero = 1 hacer sig. instr.
    CALL   MODO5
    CLRF   FMODO         ; RESETAR SI FMODO = 4
    MOVLW  0
    XORWF  FMODO, F
    BTFSC  STATUS, 2     ; Si zero = 1 hacer sig. instr.
    CALL   MODO1
    RETURN
    
MODO1: 
    BSF    PORTB, 3     ; Los led contarán en binario indicando en qué modo
    BCF    PORTB, 4     ; se está por lo que modo 1 = 1
    BCF    PORTB, 5  
    RETURN
MODO2:
    BCF    PORTB, 3     ; Modo 2, se enciende el segundo led
    BSF    PORTB, 4
    BCF    PORTB, 5
    BTFSC   FLAG, 1
    CALL    INC2
    BTFSC   FLAG, 2
    CALL    DEC2
    MOVF    TEMP_TIEMPO1, 0
    MOVWF   TIEMPO4
    BCF     RBIF
    RETURN
INC2: 
    BTFSS   FLAG_ID, 0
    RETURN
    INCF    TEMP_TIEMPO1
    BCF     FLAG_ID, 0
    MOVLW   20
    XORWF   TEMP_TIEMPO1, W
    BTFSS   STATUS, 2
    RETURN
    MOVLW   10
    MOVWF   TEMP_TIEMPO1
    RETURN
DEC2:
    BTFSS   FLAG_ID, 1
    RETURN
    DECF    TEMP_TIEMPO1
    BCF     FLAG_ID, 1
    MOVLW   9
    XORWF   TEMP_TIEMPO1, 1
    BTFSS   STATUS, 2
    RETURN
    MOVLW   20
    MOVWF   TEMP_TIEMPO1   
    RETURN
MODO3:
    BSF    PORTB, 3     ; Modo 3, enciende los primeros dos leds
    BSF    PORTB, 4
    BCF    PORTB, 5 
    BTFSC   FLAG, 1
    CALL    INC3
    BTFSC   FLAG, 2
    CALL    DEC3
    MOVF    TEMP_TIEMPO1, 2
    MOVWF   TIEMPO4
    BCF     RBIF    
    RETURN
INC3: 
    BTFSS   FLAG_ID, 0
    RETURN
    INCF    TEMP_TIEMPO2
    BCF     FLAG_ID, O 
    MOVLW   20
    XORWF   TEMP_TIEMPO2, W
    BTFSS   STATUS, 2
    RETURN
    MOVLW   10
    MOVWF   TEMP_TIEMPO2
    RETURN
DEC3:
    BTFSS   FLAG_ID, 1
    RETURN
    DECF    TEMP_TIEMPO2
    BCF     FLAG_ID, 1
    MOVLW   9
    XORWF   TEMP_TIEMPO2, W
    BTFSS   STATUS, 2
    RETURN
    MOVLW   20
    MOVWF   TEMP_TIEMPO2
    RETURN
    
MODO4:
    BCF    PORTB, 3     ; Modo 4, enciende el 3er led
    BCF    PORTB, 4
    BSF    PORTB, 5
    BTFSC   FLAG, 1
    CALL    INC4
    BTFSC   FLAG, 2
    CALL    DEC4
    MOVF    TEMP_TIEMPO3, W
    MOVWF   TIEMPO4
    BCF     RBIF
    RETURN
INC4:
    BTFSS  FLAG_ID, 0
    RETURN
    INCF    TEMP_TIEMPO3
    BCF    FLAG_ID, 0
    MOVLW  20
    XORWF   TEMP_TIEMPO3, W
    BTFSS   STATUS, 2
    RETURN
    MOVLW   10
    MOVWF   TEMP_TIEMPO3
DEC4: 
    BTFSS  FLAG_ID, 1
    RETURN
    DECF    TEMP_TIEMPO3		;DECREMENTAMOS LA VARIABLE DE CAMBIO VIA 1
    BCF	    FLAG_ID,	1	;LIMPIAMOS LA BANDERA
    MOVLW   0X09		 ;CARGAMOS EL VALOR DE 9
    XORWF   TEMP_TIEMPO3, W		 ;EL VALOR NO DECREMENTE MENOS DE 9
    BTFSS   ZERO
    RETURN
    MOVLW   0X14		;COLOCAR EL VALOR DE 20 A LA VARIABLE
    MOVWF   TEMP_TIEMPO3
    RETURN 
MODO5:
    BSF    PORTB, 3     ; Modo 5, enciende el 3ro y primer led
    BCF    PORTB, 4
    BSF    PORTB, 5
    BTFSC   FLAG, 1     ; Testear que botón se presionó
    CALL    ACEPTAR
    BTFSC   FLAG, 2     
    CALL    NEGAR
    RETURN
  ACEPTAR:
    BCF	    FLAG, 1	       ; Limpiar la FLAG
    MOVLW   0XFF		; Encender todas las LEDS
    MOVWF   PORTA
    BSF	    PORTB, 7
    MOVLW   01100111B
    MOVWF   PORTC
    MOVLW   00111111B		; Encender todas las LEDS como indicativo
    MOVWF   PORTD
    RETURN
 NEGAR:
    BCF	    FLAG, 2	        ; Limpiar la FLAG
    MOVF    TIEMPO11,   W		; Variables originales a las variables de cambio
    MOVWF   TEMP_TIEMPO1
    MOVF    TIEMPO22,   W
    MOVWF   TEMP_TIEMPO2
    MOVF    TIEMPO33,   W
    MOVWF   TEMP_TIEMPO3
    BSF   FMODO, 0               ; Regresar al modo 0
    RETURN
    

ACC_LED:
    BCF    TMR2IF        ; Limpiar bandera de interr. TMR2
    INCF   COUNT2        ; Incrementar variable del timer 2
    MOVF   COUNT2, W     
    SUBLW  125           ; Revisar que se haya cumplido el ciclo
    BTFSS  STATUS, 2     ; ZEROFLAG = 0 se ejecuta siguiente instr.
    RETURN
    CLRF   COUNT2        ; Inicializar bandera
    MOVLW  0X01          ; El bit 1 debe oscilar entre 0 y 1 cada 250ms 
    XORWF  FLAG1, F       ; El resultado se guarda en F
    RETURN
 
; C O L O R E S    D E L    S E M Á F O R O 
    
AMA1:                   ; Color amarillo primer semáforo
    BCF COLOR, 0
    BCF PORTA, 0        ; Apagar verde
    BSF PORTA, 1        ; Encender amarillo
    RETURN
ROJO1:                  ; Color rojo primer semáforo
    BCF PORTA, 1        ; Apagar amarillo
    BSF PORTA, 2        ; Encender rojo
AMA2:                   ; Color amarillo segundo semáforo
    BCF COLOR, 1
    BCF PORTA, 3        ; Apagar verde
    BSF PORTA, 4        ; Encender amarillo
    RETURN
ROJO2:                  ; Color rojo segundo semáforo   
    BCF PORTA, 4        ; Apagar amarillo
    BSF PORTA, 5        ; Encender rojo
AMA3:                   ; Color amarillo tercer semáforo
    BCF COLOR, 1
    BCF PORTE, 0        ; Apagar verde
    BSF PORTE, 1        ; Encender amarillo
    RETURN
ROJO3:                  ; Color rojo tercer semáforo 
    BCF PORTE, 1        ; Apagar amarillo
    BSF PORTE, 2        ; Encender rojo     
    
; S E M A F O R O S     
SEMAFORO1:
    BTFSC   TURNO, 0      ; Flag de la vía 1
    MOVLW   6    
    XORWF   TIEMPO1, F
    BTFSC   STATUS, 2     ; ZERO = 1 
    BSF     COLOR, 0
    MOVLW   3
    XORWF   TIEMPO1, F
    BTFSC   STATUS, 0
    CALL    AMA1
    MOVLW   0 
    XORWF   TIEMPO1, F
    BTFSC   STATUS, 2
    CALL    ROJO1
    RETURN
    
SEMAFORO2:
    BTFSC   TURNO, 1       ; Flag de la vía 2
    MOVLW   6              ; Comparación a los 6s para titileo
    XORWF   TIEMPO2, F
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    BSF     COLOR, 1
    MOVLW   3              ; Comparación a los 3s para titileo
    XORWF   TIEMPO2, F
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    CALL    AMA2
    MOVLW   0              ; Comparación para ponerlo en rojo
    XORWF   TIEMPO2, F
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    CALL    ROJO2
    RETURN
    
SEMAFORO3:
    BTFSC   TURNO, 2       ; Flag de la vía 3
    MOVLW   6              ; Comparación a los 6s para titileo
    XORWF   TIEMPO3, F  
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    BSF     COLOR, 2	
    MOVLW   3              ; Comparación a los 3s para titileo
    XORWF   TIEMPO3, F
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    CALL    AMA3
    MOVLW   0              ; Comparación para ponerlo en rojo
    XORWF   TIEMPO3, F
    BTFSC   STATUS, 2      ; ZERO = 1, hacer sig. instr.
    CALL    ROJO3
    RETURN    
    
Var_regresiva1:
    CALL    timer0        ; Inicializar timer 0
    INCF    TIEMPO        ; Contabilizar las veces que se realiza el ciclo
    MOVLW   125           ; Repetir 250 veces para hacer 1S
    SUBWF   TIEMPO, 0     ; El resultado se queda en W
    BTFSS   STATUS, 2     ; Zero = 0 entonces se realiza la sig. instr.
    RETURN 
    CLRF    TIEMPO
    DECF    TIEMPO1       ; Decrementar el tiempo VÍA 1
    DECF    TIEMPO2       ; Decrementar el tiempo VÍA 2
    DECF    TIEMPO3       ; Decrementar el tiempo VÍA 3
    RETURN      
    
Var_regresiva2:   
    CALL    timer0           ; Inicializar timer0
    INCF    TIEMPOO          ; Incrementar la variable del tiempo
    MOVLW   125              ; Repetir 125 veces
    SUBWF   TIEMPOO
    BTFSS   STATUS, 2        ; Zero = 0 entonces se realiza la sig. instr.
    RETURN
    MOVF    TEMP_TIEMPO1, 0  ; Variable temporal se guarda en w
    MOVWF   TIEMPO11         ; 
    MOVF    TEMP_TIEMPO2, 0
    MOVWF   TIEMPO22
    MOVF    TEMP_TIEMPO3, 0
    MOVWF   TIEMPO33
    CALL    ROJO3
    MOVLW   01001100B		; CONFIG. estado inicial del semaforo
    MOVWF   PORTA               ; Los LEDS del semáforo
    BCF	    PORTB,  7           
    CLRF    COLOR				
    BSF     FMODO, 0
    RETURN     

    ;      S U B R U T I N A S     P A R A    L O S    D I S P L A Y S    
DISPLAYS1:    
    MOVF   DEC1, W        ; Decenas display 1
    CALL   Tabla
    MOVWF  DIVISOR 
    MOVF   UN1, W         ; Unidades display 1
    CALL   Tabla
    MOVWF  DIVISOR+1 
   
    MOVF   DEC2, W        ; Decenas display 2
    CALL   Tabla
    MOVWF  DIVISOR2 
    MOVF   UN2, W         ; Unidades display 2
    CALL   Tabla
    MOVWF  DIVISOR2+1  
    
    MOVF   DEC3, W        ; Decenas display 3
    CALL   Tabla
    MOVWF  DIVISOR3 
    MOVF   UN3, W         ; Unidades display 3
    CALL   Tabla
    MOVWF  DIVISOR3+1    
      
    MOVF   DEC4, W        ; Decenas display 4
    CALL   Tabla
    MOVWF  DIVISOR4
    MOVF   UN4, W         ; Unidades display 4
    CALL   Tabla
    MOVWF  DIVISOR4+1  
    RETURN 

DISPLAY1: 
    CALL   timer0
    CLRF   PORTD
    BTFSC  DISP, 0       
    goto   DISPLAY12      ; UNIDADES segundo display de la vía 1
    BTFSC  DISP, 1
    goto   DISPLAY11      ; DECENAS primer display de la vía 1 
    
    BTFSC  DISP, 2 
    goto   DISPLAY22      ; UNIDADES segundo display de la vía 2
    BTFSC  DISP, 3
    goto   DISPLAY21      ; DECENAS primer display de la vía 2
    
    BTFSC  DISP, 4 
    goto   DISPLAY32      ; UNIDADES segundo display de la vía 3
    BTFSC  DISP, 5
    goto   DISPLAY31      ; DECENAS primer display de la vía 3
    
    BTFSC  DISP, 6 
    goto   DISPLAY42      ; UNIDADES segundo display de la vía 4
    BTFSC  DISP, 7
    goto   DISPLAY41      ; DECENAS primer display de la vía 4
    BCF    INTCON, 2
    
DISPLAY11:                ; SEMÁFORO VÍA 1
    MOVF   DIVISOR, W     ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 2
    MOVLW  00000100B
    MOVWF  DISP
    RETURN
DISPLAY12:
    MOVF   DIVISOR+1, W   ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 3
    MOVLW  00000010B
    MOVWF  DISP
    RETURN
    
DISPLAY21:                ; SEMÁFORO VÍA 2
    MOVF   DIVISOR2, W    ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 4
    MOVLW  00010000B
    MOVWF  DISP
    RETURN
DISPLAY22:
    MOVF   DIVISOR2+1, W  ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 5
    MOVLW  00001000B
    MOVWF  DISP
    RETURN
    
DISPLAY31:                ; EMÁFORO VÍA 3
    MOVF   DIVISOR3, w    ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 6
    MOVLW  01000000B
    MOVWF  DISP
    RETURN
DISPLAY32:
    MOVF   DIVISOR3+1, W  ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 7
    MOVLW  00100000B
    MOVWF  DISP
    RETURN
    
DISPLAY41:                ; SEMÁFORO INDICADOR DE VÍA
    MOVF   DIVISOR4, w    ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 0
    MOVLW  00000001B
    MOVWF  DISP
    RETURN
DISPLAY42:
    MOVF   DIVISOR4+1, w  ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 1
    MOVLW  10000000B
    MOVWF  DISP
    RETURN
    
DECC:                    ; DISPLAY VÍA 1
    CLRF   Bin
    MOVF   TIEMPO1, W    ; Cargar el valor de la variable    
    MOVWF  Bin
    CLRF   DEC1          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin, F        ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   DEC1, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin, F        ; Sumar 10 al valor para no perder el numero
    RETURN    
UNN: 
    CLRF   UN1
    MOVLW  1
    SUBWF  Bin, F        ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   UN1, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin, F        ; Sumarle 1
    RETURN

DECC2:                   ; DISPLAY VÍA 2
    CLRF   Bin2
    MOVF   TIEMPO2, W    ; Cargar el valor de la variable    
    MOVWF  Bin2
    CLRF   DEC2          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin2, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   DEC2, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin2, F       ; Sumar 10 al valor para no perder el numero
    RETURN     
UNN2: 
    CLRF   UN2
    MOVLW  1
    SUBWF  Bin2, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   UN2, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin2, F       ; Sumarle 1
    RETURN
    
DECC3:                   ; DISPLAY VÍA 3
    CLRF   Bin3
    MOVF   TIEMPO3, W    ; Cargar el valor de la variable    
    MOVWF  Bin3
    CLRF   DEC3          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin3, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   DEC3, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin3, F       ; Sumar 10 al valor para no perder el numero
    RETURN     
UNN3: 
    CLRF   UN3
    MOVLW  1
    SUBWF  Bin3, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   UN3, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin3, F       ; Sumarle 1
    RETURN   
    
DECC4:                   ; DISPLAY INDICADOR DE VÍA
    CLRF   Bin4
    MOVF   TIEMPO4, W    ; Cargar el valor de la variable    
    MOVWF  Bin4
    CLRF   DEC4          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin4, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   DEC4, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin4, F       ; Sumar 10 al valor para no perder el numero
    RETURN       
UNN4: 
    CLRF   UN4
    MOVLW  1
    SUBWF  Bin4, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   UN4, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin4, F       ; Sumarle 1
    RETURN
    
END