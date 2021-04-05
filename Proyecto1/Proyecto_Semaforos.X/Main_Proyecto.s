; ------------------------------------------------------------------------------
;                         Identificaci�n del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripci�n del programa: Sistema de sem�foros para controlar 3 v�as. 
    
; Hardware: 3 push buttons en el PB, 4 pares de displays multiplexados en el PC
;           con los pines de control en el PD. Asimismo, se incluyen 8 LEDs en 
;           el PA y 3 LEDs en el PE. 
    
; Creado: 13/03
; �ltima modificaci�n: 
;-------------------------------------------------------------------------------    
;-------------------------------------------------------------------------------  

PROCESSOR 16F887
#include <xc.inc>
    
;CONFIGURATION WORD 1
 CONFIG FOSC=INTRC_NOCLKOUT // Oscillador interno I/O RA6
 CONFIG WDTE=OFF            // WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=OFF           // PWRT enabled (espera de 72ms)
 CONFIG MCLRE=OFF           // El pin de MCLR se utiliza como I/O
 CONFIG CP=OFF              // Sin protecci�n de c�digo
 CONFIG CPD=OFF             // Sin protecci�n de datos

 CONFIG BOREN=OFF           // No reinicia cu�ndo v de alimentaci�n baja de 4v
 CONFIG IESO=OFF            // Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF           // Cambio de reloj externo a interno en caso falla
 CONFIG LVP=OFF              // Progra en bajo voltaje permitido
 
;CONFIGURATION WORD 2
 CONFIG WRT=OFF             // Protecci�n de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;VARIABLES A UTILIZAR
 PSECT udata_bank0     ; common memory             
   W_TEMP:    DS 1     ; Variable temporal
   STAT_TEMP: DS 1     ; Variable temporal
   FLAG:      DS 1     ; Variable para los botones
   FMODO:     DS 1     ; Variable para los modos
   DISP:      DS 1     ; Flag de los DISPLAYS
   TIEMPO:    DS 1     ; Variable queee cuenta los ciclos del TMR0
   COLOR:     DS 1     ; Flag para los colores del sem�foro
    
   TIEMPO1:   DS 1     ; Variable para el tiempo
   Bin:       DS 1
   TIEMPO2:   DS 1     ; Variable para el tiempo V�A 2
   Bin2:      DS 1
   TIEMPO3:   DS 1     ; Variable para el tiempo V�A 3
   Bin3:      DS 1
   TIEMPO4:   DS 1     ; Variable para el tiempo INDICADOR DE V�A
   Bin4:      DS 1
    
   UN1:       DS 1     ; Variable unidades DISPLAY1
   DEC1:      DS 1     ; Variable decenas DISPLAY1
   UN2:       DS 1     ; Variable unidades DISPLAY2
   DEC2:      DS 1     ; Variable decenas DISPLAY2
   UN3:       DS 1     ; Variable unidades DISPLAY3
   DEC3:      DS 1     ; Variable decenas DISPLAY3
   UN4:       DS 1     ; Variable unidades DISPLAY4
   DEC4:      DS 1     ; Variable decenas DISPLAY4
   DIVISOR:   DS 2     ; Variables con los valores a mostrar
   DIVISOR2:  DS 2
   DIVISOR3:  DS 2
   DIVISOR4:  DS 2 
;_______________________________________________________________________________
;                          V E C T O R   R E S E T  
;_______________________________________________________________________________   
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
 
 ORG 00h               ; Posici�n 0000h para el reset
 resetVec:PAGESEL main
    goto main	
;_______________________________________________________________________________
;                        V E C T O R   I N T E R R U P T 
;_______________________________________________________________________________
 ORG 004h               ; Posici�n 004 para la interrupci�n
 
PUSH: 
   BCF   INTCON, 7     ; Desact. general interrupt (evitar interr. simultaneas)
   MOVWF W_TEMP        ; Guardar lo que se encuentra en w
   SWAPF STATUS, W     ; Guardar stat. a W sin MOVF (no afectar banderas de stat.)
   MOVWF STAT_TEMP     ; Guardar lo de W en variable temporal
     
ISR:                   ; (Interrupciones) chequear que la bandera est� encendida
  ; BTFSC INTCON, 0    ; RBIF PB change interrupt flag (Ver si cambi� estado)
  ; CALL  Button
   BTFSC INTCON, 2     ; Testear bandera del TOIF (overflow del TMR0)
   CALL  Var_regresiva
   CALL  DISPLAY1
   ;BTFSC INTCON, 2   ; Testear bandera del TOIF
   ; CALL ALGO NTA
   ;BTFSC PIR1, 1     ; Flag del Match de TMR2 con PR2
   ;CALL TITILEO
       
POP:  
   SWAPF STAT_TEMP, W  ; Regresando el valor al original
   MOVWF STATUS        ; Regresarlo a STATUS
   SWAPF W_TEMP, F     ; darle vuelta a los nibbles de Wtemp
   SWAPF W_TEMP, W     ; Regresamos al orden original y guardamos en w
   RETFIE              ; Regresar de la interrupci�n (incluye reactivacion del GIE) 	
   
;_______________________________________________________________________________
;                          S U B R U T I N A 
;                    V E C T O R   I N T E R R U P T 
;_______________________________________________________________________________    
    
;Button: 
 ;    BCF   STATUS, 0     ; Limpiar bandera de carry
 ;   BTFSS PORTB, 0      ; Revisar MODO (1er pin del PORTB)
  ;  BSF   FLAG,  0      ; Setear FLAG
   ; BTFSS PORTB, 1      ; Revisar ARRIBA (2do pin del PORTB)
   ; BSF   FLAG,  1      ; Setear FLAG
   ; BTFSS PORTB, 2      ; Revisar ABAJO (3er pin del PORTB)
   ; BSF   FLAG,  2      ; Setear FLAG
   ; BCF   INTCON, 0     ; Limpiar FLAG RBIF
   ; RETURN 

;----------------------------- D I S P L A Y ----------------------------------
   
PSECT code, delta=2, abs ; A partir de ac� es c�digo
ORG 0100h                ;posici�n para el c�digo
 
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
    banksel ANSEL          ; Ir al registro donde est� ANSEL
    CLRF    ANSEL          ; pines digitales
    CLRF    ANSELH         ; Puerto B digital  
         
    banksel TRISA          ; Ir al banco en donde est� TRISA
    BSF     TRISB, 0       ; MODO
    BSF     TRISB, 1       ; INCREMENTO
    BSF     TRISB, 2       ; DECREMENTO
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
    banksel PORTA           ; Ir al banco donde est� PORTA
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
    BCF     DISP, 2
    BCF     DISP, 3
    BCF     DISP, 4
    BCF     DISP, 5
    BCF     DISP, 6
    BCF     DISP, 7
    CLRF    DIVISOR
    CLRF    COLOR
    
    CLRF    FMODO           ; Inicia en el primer modo
    MOVLW   10              ; Inicializar sem�foros tiempo con 10 segundos
    MOVWF   TIEMPO1, F
    MOVWF   TIEMPO2, F
    MOVWF   TIEMPO3, F
    MOVF    TIEMPO2, W
    ADDWF   TIEMPO3, F      ; TIEMPO de la 3era v�a es V�A1 + V�A 2
    
    banksel PORTA               ; Inicializar sem�foros (LEDS)
    BSF     PORTB, 3            ; Contador de LEDS en 1
    BCF     PORTB, 4
    BCF     PORTB, 5
    MOVLW   00001100B		; Primeros dos sem�foros
    MOVWF   PORTA
    MOVLW   0001B               ; Tercer sem�foro
    MOVWF   PORTE
    RETURN
    
Interrupciones:
    banksel INTCON          ; Configuraciones para TMR0
    BCF     INTCON, 0       ; RBIF Limpiar la bandera de CHANGE INTERRUPT
    BCF     INTCON, 2       ; T0IF Limpiar la bandera del TMR0
    BSF     INTCON, 3       ; RBIE Encender interrupci�n PORTB CHANGE
    BSF     INTCON, 5       ; T0IE Encender interrupci�n de OVERFLOW TMR0 
    BSF     INTCON, 6       ; PEIE Encender interrupci�n perif�rica
    BSF     INTCON, 7       ; GIE Encender interrupci�n de global
    
    banksel OPTION_REG      ; Configuraciones para TMR2
    BSF     PIE1,   1       ; TMR1IE Encender interrupci�n de OVERFLOW TMR2
    banksel TMR0
    BSF     T2CON,  2       ; Encender el timer2
    BCF     PIR1,   1       ; TMR2IF TIMER2 to PR2 Interrupt Flag
    BCF     STATUS, 2       ; Limpiar bandera de Zero
    RETURN

;--------------- E C U A C I � N     T E M P O R I Z A D O R -------------------
;              Temporizaci�n : 4*TOSC*TMR0*Prescaler (predivisor)
    
PRE0:
    BCF     PSA            ; Prescaler se le asigna al m�dulo TMR0
    CLRWDT                 ; Clear watch dog y prescalador
    banksel OPTION_REG     ; Ir al banco donde est� Op. reg
    MOVLW   11010000B      ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W  ; Prescaler bit
    IORLW   00000100B      ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    RETURN

timer0: 
    banksel TMR0           ; Ir al banco de TMR0
    MOVLW   131            ; TMR0 = 125
    MOVF    TMR0           ; Moverlo a TMR0
    BCF     INTCON, 2      ; Bandera de overflow (viene con v desconocido)
    RETURN 
 
;PRE2:
   ; banksel T2CON
  ;  MOVLW   01001001B      ; Postscaler de 10  y prescaler de 4
 ;   MOVWF   T2CON
;    CALL    timer2
   ; banksel TMR0
    ;BCF     PIR1, 1
    ;RETURN
    
;timer2:
 ;   banksel OPTION_REG
  ;  MOVLW   50              ; Valor inicial del registro del TMR2
   ; MOVWF   PR2             ; Obtener un TMR2IF de 2ms
   ; RETURN    
        
main: 
    banksel OSCCON
    BSF     SCS            ; Utilizar oscilador interno
    CALL    config_pines
    CALL    weak_PU
    CALL    Interrupciones
    CALL    Inicializar
    CALL    PRE0
    CALL    timer0         ; Inicializar el timer
    ;CALL    PRE2
    ;CALL    timer2
;_______________________________________________________________________________
;                                L O O P 
;_______________________________________________________________________________
    
 Loop:
    ;BTFSC   FLAG, 0
    ;CALL    MODOS
    ;BTFSC   FLAG, 1
    ;CALL    ARRIBA
    ;BTFSC   FLAG, 2
    ;CALL    ABAJO
    
    CALL    DECC          ; Decenas primer sem�foro
    CALL    UNN           ; Unidades primer sem�foro  
    CALL    DECC2          ; Decenas segundo sem�foro
    CALL    UNN2           ; Unidades segundo sem�foro
    CALL    DECC3          ; Decenas tercer sem�foro
    CALL    UNN3           ; Unidades tercer sem�foro
    CALL    DECC4          ; Decenas Indicador de V�a
    CALL    UNN4           ; Unidades
    CALL    DISPLAYS1  
    
    ;BTFSC   VIA,    0
    ;CALL    SEMAFORO1		;FUNCIONAMIENTO DEL SEMAFORO VIA 1
    ;BTFSC   VIA,    1
    ;CALL    SEMAFORO2		;FUNCIONAMIENTO DEL SEMAFORO VIA 2		
    ;BTFSC   VIA,    2
    ;CALL    SEMAFORO3		;FUNCIONAMIENTO DEL SEMAFORO VIA 3
    ;CALL    TITILAR1		;TITILITEO DEL SEMAFORO 1
    ;CALL    TITILAR2		;TITILITEO DEL SEMAFORO 2
    ;CALL    TITILAR3		;TITILITEO DEL SEMAFORO 3
    ;CALL    MODE		;LLAMAMOS A MODO DE CONFIGURACION 
    goto    Loop
;_______________________________________________________________________________
;                          S U B R U T I N A S 
;_______________________________________________________________________________
    
Var_regresiva:
    CALL    timer0        ; Inicializar timer 0
    INCF    TIEMPO
    MOVLW   250
    SUBWF   TIEMPO, 0     ; El resultado se queda en W
    BTFSS   STATUS, 2     ; Zero = 0 entonces se realiza la sig. instr.
    RETURN 
    CLRF    TIEMPO
    DECF    TIEMPO1       ; Decrementar el tiempo V�A 1
    DECF    TIEMPO2       ; Decrementar el tiempo V�A 2
    DECF    TIEMPO3       ; Decrementar el tiempo V�A 3
    RETURN 
    
DISPLAYS1: 
    MOVF   UN1, W         ; Unidades display 1
    CALL   Tabla
    MOVWF  DIVISOR+1    
    MOVF   DEC1, W        ; Decenas display 1
    CALL   Tabla
    MOVWF  DIVISOR 
    
    MOVF   UN2, W         ; Unidades display 2
    CALL   Tabla
    MOVWF  DIVISOR2+1    
    MOVF   DEC2, W        ; Decenas display 2
    CALL   Tabla
    MOVWF  DIVISOR2 
    
    MOVF   UN3, W         ; Unidades display 3
    CALL   Tabla
    MOVWF  DIVISOR3+1    
    MOVF   DEC3, W        ; Decenas display 3
    CALL   Tabla
    MOVWF  DIVISOR3 
    
    MOVF   UN4, W         ; Unidades display 4
    CALL   Tabla
    MOVWF  DIVISOR4+1    
    MOVF   DEC4, W        ; Decenas display 4
    CALL   Tabla
    MOVWF  DIVISOR4
    RETURN 

DISPLAY1: 
    CLRF   PORTD
    CALL   timer0
    BTFSC  DISP, 0        ; Subrutina verificar qu� display se le carga el valor
    goto   DISPLAY12      ; UNIDADES segundo display de la v�a 1
    BTFSC  DISP, 1
    goto   DISPLAY11      ; DECENAS primer display de la v�a 1 
    
    BTFSC  DISP, 2 
    goto   DISPLAY22      ; UNIDADES segundo display de la v�a 2
    BTFSC  DISP, 3
    goto   DISPLAY21      ; DECENAS primer display de la v�a 2
    
    BTFSC  DISP, 4 
    goto   DISPLAY32      ; UNIDADES segundo display de la v�a 3
    BTFSC  DISP, 5
    goto   DISPLAY31      ; DECENAS primer display de la v�a 3
    
    BTFSC  DISP, 6 
    goto   DISPLAY42      ; UNIDADES segundo display del indicador de v�a
    BTFSC  DISP, 7
    goto   DISPLAY41      ; DECENAS primer display del indicador de v�a
    
DISPLAY11:                ; SEM�FORO V�A 1
    MOVF   DIVISOR, w     ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 2
    MOVLW  00000100B
    MOVWF  DISP
    RETURN
DISPLAY12:
    MOVF   DIVISOR+1, w   ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 3
    MOVLW  00000010B
    MOVWF  DISP
    RETURN
    
DISPLAY21:                ; SEM�FORO V�A 2
    MOVF   DIVISOR2, w    ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 4
    MOVLW  00010000B
    MOVWF  DISP
    RETURN
DISPLAY22:
    MOVF   DIVISOR2+1, w  ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 5
    MOVLW  00001000B
    MOVWF  DISP
    RETURN
    
DISPLAY31:                ; EM�FORO V�A 3
    MOVF   DIVISOR3, w    ; Decenas
    MOVWF  PORTC
    BSF    PORTD, 6
    MOVLW  01000000B
    MOVWF  DISP
    RETURN
DISPLAY32:
    MOVF   DIVISOR3+1, w  ; Unidades
    MOVWF  PORTC
    BSF    PORTD, 7
    MOVLW  00100000B
    MOVWF  DISP
    RETURN
    
DISPLAY41:                ; SEM�FORO INDICADOR DE V�A
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
    
DECC:                    ; DISPLAY V�A 1
    CLRF   Bin
    MOVF   TIEMPO1, W    ; Cargar el valor de la variable    
    MOVWF  Bin
    CLRF   DEC1          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin, F        ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   DEC1, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin, F        ; Sumar 10 al valor para no perder el numero
    RETURN    
UNN: 
    CLRF   UN1
    MOVLW  1
    SUBWF  Bin, F        ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   UN1, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin, F        ; Sumarle 1
    RETURN

DECC2:                   ; DISPLAY V�A 2
    CLRF   Bin2
    MOVF   TIEMPO2, W    ; Cargar el valor de la variable    
    MOVWF  Bin2
    CLRF   DEC2          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin2, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   DEC2, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin2, F       ; Sumar 10 al valor para no perder el numero
    RETURN     
UNN2: 
    CLRF   UN2
    MOVLW  1
    SUBWF  Bin2, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   UN2, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin2, F       ; Sumarle 1
    RETURN
    
DECC3:                   ; DISPLAY V�A 3
    CLRF   Bin3
    MOVF   TIEMPO3, W    ; Cargar el valor de la variable    
    MOVWF  Bin3
    CLRF   DEC3          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin3, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   DEC3, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin3, F       ; Sumar 10 al valor para no perder el numero
    RETURN     
UNN3: 
    CLRF   UN3
    MOVLW  1
    SUBWF  Bin3, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   UN3, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin3, F       ; Sumarle 1
    RETURN   
    
DECC4:                   ; DISPLAY INDICADOR DE V�A
    CLRF   Bin4
    MOVF   TIEMPO4, W    ; Cargar el valor de la variable    
    MOVWF  Bin4
    CLRF   DEC4          ; Limpiar variable
    MOVLW  10
    SUBWF  Bin4, F       ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   DEC4, 1       ; Incrementar decenas
    BTFSC  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    goto   $-4
    ADDWF  Bin4, F       ; Sumar 10 al valor para no perder el numero
    ;BTFSC  FFMODO, 0     ; Si est� en Modo 1
    ;goto   OFFDECC4
    ;BTFSC  FFMODO, 4     ; Si est� en modo 5
    ;goto   OFFDECC4
    RETURN       
UNN4: 
    CLRF   UN4
    MOVLW  1
    SUBWF  Bin4, F       ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurri� un borrow
    INCF   UN4, 1        ; Incrementar unidades
    BTFSC  STATUS, 0 
    goto   $-4
    ADDWF  Bin4, F       ; Sumarle 1
    ;BTFSC  FFMODO, 0     ; Si est� en Modo 1
    ;goto   OFFUNN4
    ;BTFSC  FFMODO, 4     ; Si est� en modo 5
    ;goto   OFFUNN4   
    RETURN
;OFFDECC4:
  ;  MOVLW   00001010B		;Apagar display de decenas
   ; MOVWF   DEC4
;OFFUNN4:
 ;   MOVLW   00001010B		;Apagar display de unidades
  ;  MOVWF   UN4
    
;AMA1:                   ; Color amarillo primer sem�foro
    ;BCF COLOR, 0
    ;BFC PORTA, 0        ; Apagar verde
    ;BSF PORTA, 1        ; Encender amarillo
    ;RETURN
;ROJO1:                  ; Color rojo primer sem�foro
    ;BCF PORTA, 1        ; Apagar amarillo
    ;BSF PORTA, 2        ; Encender rojo
    
;AMA2:                   ; Color amarillo segundo sem�foro
    ;BCF COLOR, 1
    ;BFC PORTA, 3        ; Apagar verde
    ;BSF PORTA, 4        ; Encender amarillo
    ;RETURN
;ROJO2:                  ; Color rojo segundo sem�foro   
    ;BCF PORTA, 4        ; Apagar amarillo
    ;BSF PORTA, 5        ; Encender rojo
    
;AMA3:                   ; Color amarillo tercer sem�foro
    ;BCF COLOR, 1
    ;BFC PORTE, 0        ; Apagar verde
    ;BSF PORTE, 1        ; Encender amarillo
    ;RETURN
;ROJO3:                  ; Color rojo tercer sem�foro 
    ;BCF PORTE, 1        ; Apagar amarillo
    ;BSF PORTE, 2        ; Encender rojo    
    
// Para los modos pero esto es una prueba nt    
// Interrupcion con el cambio asi que INTERRUPT CHANGE DEL PUERTO B
    
END
    

