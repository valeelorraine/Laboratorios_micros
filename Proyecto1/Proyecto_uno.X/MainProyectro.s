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
;           el PA y 2 LEDs en el PE. 
    
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
 CONFIG LVP=ON              // Progra en bajo voltaje permitido
 
;CONFIGURATION WORD 2
 CONFIG WRT=OFF             // Protección de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;VARIABLES A UTILIZAR
 PSECT udata_bank0     ; common memory             
   W_TEMP:    DS 1     ; Variable temporal
   STAT_TEMP: DS 1     ; Variable temporal
   FLAG:      DS 1 

    
 ;------------------------ V E C T O R   R E S E T -----------------------------
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
 
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
     
ISR:                    ; (Interrupciones) chequear que la bandera está encendida
    BTFSC INTCON, 2     ; Testear bandera del overflow del TMR0
    CALL
      
POP:  
    SWAPF STAT_TEMP, W  ; Regresando el valor al original
    MOVWF STATUS        ; Regresarlo a STATUS
    SWAPF W_TEMP, F     ; darle vuelta a los nibbles de Wtemp
    SWAPF W_TEMP, W     ; Regresamos al orden original y guardamos en w
    RETFIE              ; Regresar de la interrupción (incluye reactivacion del GIE) 	
    
    
; -------------------------- S U B R U T I N A ---------------------------------
;                    V E C T O R   I N T E R R U P T 
    
Button: 
    BTFSS PORTB, 0      ; Revisar 1er pin del PORTB
    BSF   FLAG,  0      ; Setear FLAG
    BTFSS PORTB, 1      ; Revisar 2do pin del PORTB
    BSF   FLAG,  1
    BCF   INTCON,0      ; Limpiar FLAG RBIF
    RETURN

    
;----------------------------- D I S P L A Y ----------------------------------
 
PSECT code, delta=2, abs ; A partir de acá es código
ORG 0100h                ;posición para el código
 
Tabla:
    CLRF   PCLATH 
    BSF    PCLATH, 0     ; Limpiar program counter, 0100h
    ANDLW  0X0f          ; No sumar más de 15	
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
    
main: 
    banksel OSCCON
    BSF     SCS            ; Utilizar oscilador interno
     
    CALL    config_pines
    CALL    weak_PU
    CALL    Inicializar
    CALL    Interrupciones
    CALL    PRE0
    CALL    timer0          ; Inicializar el timer
    CLRF    W_TEMP          ; Inicializar las variables
    CLRF    STAT_TEMP 
    CLRF    FLAG 

Loop:

    RETURN
;_______________________________________________________________________________ 
;                           S U B R U T I N A 
;                               Etiquetas
;_______________________________________________________________________________

; CONFIGURACIONES 
config_pines:
    banksel ANSEL          ; Ir al registro donde está ANSEL
    CLRF    ANSEL          ; pines digitales
    CLRF    ANSELH         ; Puerto B digital  
         
    banksel TRISA          ; Ir al banco en donde está TRISA
    BSF     TRISB, 0       ; MODO
    BSF     TRISB, 1       ; INCREMENTO
    BSF     TRISB, 2       ; DECREMENTO
    CLRF    TRISA          ; Puertos = outputs
    CLRF    TRISC
    CLRF    TRISD
    CLRF    TRISE
    RETURN
 
;----------------------- W E A K   P U L L   U P -------------------------------
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
    RETURN
    
Interrupciones:
    banksel INTCON
    BSF     INTCON, 2       ; Encender interrupción de overflow TMR2
    BSF     INTCON, 3       ; Encender interrupción de PORTB
    BSF     INTCON, 5       ; Encender TOIE interrupción de TMR0 
    BSF     INTCON, 7       ; Encender GIE interrupción de global
    banksel PORTA
    RETURN

;--------------- E C U A C I Ó N     T E M P O R I Z A D O R -------------------
;                 Tosc 1 = contador y Tosc = 0 temporizador
    
; D O N D E: 
;           Temporización : 4*TOSC*TMR0*Prescaler (predivisor)
;           TOSC = 1/FOSC
;           TMR0 = 256-N (valor a cargar en TMR0)
    
PRE0:
    BCF     PSA            ; Prescaler se le asigna al módulo TMR0
    CLRWDT                 ; Clear watch dog y prescalador
    banksel OPTION_REG     ; Ir al banco donde está Op. reg
    MOVLW   11010000B      ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W  ; Prescaler bit
    IORLW   00000100B      ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    RETURN

timer0: 
    banksel TMR0           ; Ir al banco de TMR0
    MOVLW   6              ; Cargar N = 6 (viene de la ecuación de t)
    MOVF    TMR0           ; Moverlo a TMR0
    BCF     INTCON, 2      ; Bandera de overflow (viene con v desconocido)
    RETURN 
    
;_______________________________________________________________________________
;                            A C C I O N E S 
;_______________________________________________________________________________

Var_regresiva:
    BTFSS   INTCON, 2	   ; F = 0 ejecutar siguiente instr.
    goto    $-1 
    CALL    timer0         ; Inicializar timer 1
    MOVLW   125
    SUBWF   TIEMPO1, 0      ; Ver cuando ya pasó 1 segundo
    BTFSC   STATUS, 2       ; Zero = 1 entonces se realiza la sig. instr.
    DECF    TIEMPO1         ; Decrementar la variab  le del tiempo
    BCF     INTCON, 2       ; Limpiar la bandera del overflow
    return  
    
    CLRF    TIEMPO1
   
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