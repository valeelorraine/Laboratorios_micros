; ------------------------------------------------------------------------------
;                         Identificación del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripción del programa: Utilizar TIMER 0, 1 y 2 para configurar la intermi-
;                           tencia de un LED y dos displays multiplexados. Asi-
;                           mismo, implementar una rutina que incremente una va-
;                           riable cada segundo.
    
; Hardware: 1 LEDs en el puerto A, 2 dislay multiplexados en el puerto C y los 
;           pines de control en el puerto D.
    
; Creado: 23/03
; Última modificación: 25/03
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
 CONFIG LVP=ON              // Progra en bajo voltaje permitido
 
;CONFIGURATION WORD 2
 CONFIG WRT=OFF             // Protección de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;VARIABLES A UTILIZAR
 PSECT udata_bank0     ; Variables en el banco 0            
   W_TEMP:    DS 1     ; Variable temporal del W
   STAT_TEMP: DS 1     ; Variable temporal del STATUS
   FLAG:      DS 1 
   COUNT1:    DS 1
   COUNT2:    DS 1
   Bin:       DS 1
   SEL:       DS 1
   FSOOSA:    DS 1     ; Flag para las operaciones
   LED:       DS 1
   NUMERO:    DS 2  
   DIVISOR:   DS 2
 ;------------------------ V E C T O R   R E S E T -----------------------------
;Instrucciones del vector de reset
 PSECT resVect, class = CODE, abs, delta=2   ;(cant. de bytes para usar instr)
 
 ORG 00h               ; Posición 0000h para el reset
 resetVec:PAGESEL main
    goto main
	
	
 ;---------------------- V E C T O R   I N T E R R U P T -----------------------
 
 ORG 004h               ; Posición 004 para la interrupción
 
 PUSH: 
    BCF   INTCON, 7     ; Desact. general interrupt (evitar interr. simultaneas)
    MOVWF W_TEMP        ; Guardar lo que se encuentra en w
    SWAPF STATUS, W     ; Guardar stat. a W sin MOVF (no afectar banderas de stat.)
    MOVWF STAT_TEMP     ; Guardar lo de W en variable temporal
     
ISR:      
    BTFSC  INTCON, 2    ; Revisar T0IF interrupción de overflow TMR0
    CALL   ACC_DISP
    BTFSS  TMR1IF       ; Revisar bandera del overflow
    CALL   Inc1         ; Incrementar la variable
    BTFSC  TMR2IF       ; Revisar bandera del TMR2
    CALL   ACC_LED      ; Blinquea la led
   
POP: 
    SWAPF STAT_TEMP, W  ; Regresando el valor al original
    MOVWF STATUS        ; Regresarlo a STATUS
    SWAPF W_TEMP, F     ; darle vuelta a los nibbles de Wtemp
    SWAPF W_TEMP, W     ; Regresamos al orden original y guardamos en w
    RETFIE              ; Regresar de la interrupción (incluye reactivacion del GIE) 	
    
    
; -------------------------- S U B R U T I N A ---------------------------------
;                    V E C T O R   I N T E R R U P T 
    
Inc1:   
    call   timer1
    INCF   COUNT1           ; Incrementar contador timer 1
    MOVLW  1000       
    SUBWF  COUNT1, 0     ; 0 se guarda en w
    BTFSC  STATUS, 2     ; ZEROFLAG = 1 Ejecutar siguiente instr.
    RETURN
    
    CLRF   COUNT1        ; Inicializar variable
    INCF   Bin
    MOVLW  0X64
    XORWF  Bin, W        ; Resetear al llegar a 100
    BTFSC  STATUS, 2     ; ZEROFLAG = 1 Ejecutar siguiente instr
    CLRF   Bin
    RETURN
       
display0: 
    MOVF  DIVISOR, w         ; Decenas
    MOVWF PORTC              ; Cargar el valor al primer display
    BSF   PORTD, 1           ; Encender pin del transistor
    MOVLW 00000001B
    GOTO  CHANGE
    RETURN
   
display1:
    MOVF  DIVISOR+1, w       ; Unidades
    MOVWF PORTC              ; Cargar el valor al segundo display
    BSF   PORTD, 1           ; Encender pin del transistor
    MOVLW 00000000B
    GOTO  CHANGE
    RETURN 
    
CHANGE: 
    MOVWF  SEL, F        
    RETURN
    
 ;----------------------------- D I S P L A Y ----------------------------------
 
PSECT code, delta=2, abs ; A partir de acá es código
ORG 0100h                ;posición para el código
 
Tabla_disp:
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
    
 
;---------------------- C O N F I G U R A C I O N E S --------------------------

main: 
    banksel OSCCON
    BSF     SCS            ; Utilizar oscilador interno
    CALL    config_pines
    CALL    Inicializar
    CALL    Interrupciones
    CALL    PRE0
    CALL    PRE1
    CALL    PRE2
    CALL    Inicializar    ; Inicializar puertos y variables
    CALL    timer0
    CALL    timer1
    CALL    timer2
    
    banksel PORTA   
   
;-------------------------------- L O O P --------------------------------------
    
 loop: 
    CALL   DECC
    CALL   UN
    CALL   DISP_DECIMAL
    goto   loop
    
;-------------------------- S U B R U T I N A ----------------------------------
;                               Etiquetas

; C O N F I G U R A C I O N E S 
    
config_pines:
    banksel ANSEL          ; Ir al registro donde está ANSEL
    CLRF    ANSEL          ; pines digitales
    CLRF    ANSELH         ; Puerto B digital  
         
    banksel TRISA          ; Ir al banco en donde está TRISA
    CLRF    TRISA          ; Puertos = outputs
    CLRF    TRISC
    BCF     TRISD, 0
    BCF     TRISD, 1
    RETURN
    
Inicializar:
    banksel PORTA           ; Ir al banco donde está PORTA
    CLRF    PORTA           ; Inicializar los puertos
    CLRF    PORTB           
    CLRF    PORTC
    CLRF    PORTD
    
    CLRF    W_TEMP         ; Inicializar las variables
    CLRF    STAT_TEMP 
    CLRF    FLAG  
    CLRF    COUNT1
    CLRF    COUNT2
    CLRF    NUMERO
    CLRF    Bin
    CLRF    SEL
    CLRF    FSOOSA        ; Flag para las operaciones
    CLRF    DIVISOR   
    RETURN
    
Interrupciones:
    banksel INTCON
    BCF     INTCON, 2       ; Encender T0IF interrupción de overflow TMR2
    BSF     INTCON, 5       ; Encender TOIE interrupción de TMR0 
    BSF     INTCON, 6       ; Encender PEIE
    BSF     INTCON, 7       ; Encender GIE interrupción de global
    
    banksel OPTION_REG
    BSF     PIE1, 0         ; Encender la bandera de interrupción TMR1
    BSF     PIE1, 1         ; Encender la bandera de interrupción TMR2
    
    banksel TMR0
    BCF     TMR1IF          ; Limpiar bandera del timer 1
    BCF     TMR2IF          ; Limpiar bandera del timer 2
    BCF     STATUS, 2       ; Limpiar bandera de Zero
    RETURN
    
;_______________________________________________________________________________
;                 E C U A C I Ó N     T E M P O R I Z A D O R   
; D O N D E: 
;           Temporización : 4*TOSC*TMR0*Prescaler (predivisor)
;           TOSC = 1/FOSC
;           TMR0 = 256-N (valor a cargar en TMR0)
;_______________________________________________________________________________  
    
PRE0:
    CLRWDT                 ; Clear watch dog y prescalador
    banksel OPTION_REG     ; Ir al banco donde está Op. reg
    MOVLW   11010000B      ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W  ; Prescaler bit
    IORLW   00000001B      ; Set prescale to 1:4
    MOVWF   OPTION_REG 
    CALL    timer0
    RETURN
      
PRE1: 
    banksel T1CON
    MOVLW   00000001B
    MOVWF   T1CON          ; Prescaler de 2 para un TMR1 de 1ms
    CALL    timer1
    RETURN
    
PRE2:
    banksel T2CON
    MOVLW   01001001B      ; Postscaler de 10  y prescaler de 4
    MOVWF   T2CON
    CALL    timer2
    banksel TMR0
    BCF     PIR1, 1
    RETURN
    
timer0:                    ; TMR0
    banksel TMR0           ; Ir al banco de TMR0
    MOVLW   6              ; Cargar N = 6 (viene de la ecuación de t)
    MOVF    TMR0           ; Moverlo a TMR0
    BCF     INTCON, 2      ; Bandera de overflow (viene con v desconocido)
    RETURN 
    
timer1:
    banksel TMR0          ; Cargarle N a ambos registros (N = 65036)
    MOVLW   0xFE           ; Byte más significativo
    MOVWF   TMR1H          
    MOVLW   0x0C           ; Byte menos significativo
    MOVWF   TMR1L     
    BCF     TMR1IF         ; Limpiar bandera del timer 1
    RETURN     
    
timer2:
    banksel OPTION_REG
    MOVLW   50              ; Valor inicial del registro del TMR2
    MOVWF   PR2             ; Obtener un TMR2IF de 2ms
    RETURN
   
;_______________________________________________________________________________    
;                              A C C I O N E S 
;_______________________________________________________________________________ 
    
ACC_LED:
    BCF    TMR2IF        ; Limpiar bandera de interr. TMR2
    INCF   COUNT2        ; Incrementar variable del timer 2
    MOVF   COUNT2, W     
    SUBLW  125           ; Revisar que se haya cumplido el ciclo
    BTFSS  STATUS, 2     ; ZEROFLAG = 0 se ejecuta siguiente instr.
    RETURN
    
    CLRF   COUNT2        ; Inicializar bandera
    MOVLW  0X01          ; El bit 1 debe oscilar entre 0 y 1 cada 250ms 
    XORWF  FLAG, 1       ; El resultado se guarda en F
    BTFSC  FLAG, 1       ; Revisar LED
    BSF    PORTA, 0      ; Encender pin del LED
    BTFSS  FLAG, 1      
    BCF    PORTA, 0      ; Apagar el pin del LED
    RETURN
    
ACC_DISP:
    CALL  timer0         ; Inicializar timer 0
    BTFSS FLAG, 1    
    CALL  APAGAR         ; Apagar el display
    BTFSS FLAG, 1
    RETURN
    
    CLRF  PORTD          ; Inicializar puerto D
    BTFSC SEL, 0         ; Determinar a qué display se le cargó el valor
    GOTO  display1       
    BTFSC SEL, 1
    GOTO  display0
  
 APAGAR:
    BSF   PORTD, 1       ; Decenas
    BSF   PORTD, 0       ; Unidades
    CLRF  PORTC
    RETURN
    
; D I S P L A Y  D E C I M A L 
DISP_DECIMAL: 
    MOVF   NUMERO, W       ; Decenas
    CALL   Tabla_disp
    MOVWF  DIVISOR         ; Guardar en variable las decenas  
	
    MOVF   NUMERO+1, W     ; Unidades
    CALL   Tabla_disp
    MOVWF  DIVISOR+1       ;Guardar en variable las unidades
    RETURN

  
;_______________________________________________________________________________
;                                R E S T A
;                            UNIDADES Y DECENAS 
;_______________________________________________________________________________
    
UN: 
    CLRF   NUMERO+1      ; Limpiar decenas
    MOVLW  1
    SUBWF  Bin, F        ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   NUMERO+1, 1   ; Incrementar unidades
    BTFSS  STATUS, 0 
    BSF    FSOOSA, 2     ; Apagar resta de unidades
    BTFSS  STATUS, 0
    ADDWF  Bin, F        ; Sumarle 1 
    RETURN
    
DECC:
    BSF    FSOOSA, 2     ; Apagar bandera de unidades
    MOVWF  Bin
    CLRF   NUMERO        ; Limpiar decenas
    MOVLW  10
    SUBWF  Bin, F        ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   NUMERO, 1     ; Incrementar decenas
    BTFSS  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    BSF	   FSOOSA, 1     ; Apagar resta de decenas
    BTFSS  STATUS, 0
    BCF    FSOOSA, 2     ; Encender resta de unidades
    BTFSS  STATUS, 0
    ADDWF  Bin, F        ; Sumar 10 al valor para no perder el numero
    RETURN

END
    