; ------------------------------------------------------------------------------
;                         Identificación del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripción del programa: contador binario de 8 bits con 2 push buttons que 
;           utilicen interrupciones ON-CHANGE, pull ups internos, 8 LEDs y dos 
;           display para mostrar el valor en hexadecimal del contador. Asimismo,  
;           hacer una subrutina que convierta el valor del contador y lo guarde
;           en 3 variables en formato decimal. Utilizar procedimiento de divi-
;           sión. Implementar 3 displays de 7 segmentos multiplexados para des-
;           legar el valor del multiplexor.
    
; Hardware: 8 LEDs en el puerto A, 2 push buttons el puerto B, 5 dislay multi-
;           plexados en el puerto D y los pines de control en el puerto C.
    
; Creado: 01/03
; Última modificación: 6/03
;-------------------------------------------------------------------------------    
;-------------------------------------------------------------------------------  
    
PROCESSOR 16F887
#include <xc.inc>
    
 ;configuration word 1
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
 
;configuración word 2
 CONFIG WRT=OFF             // Protección de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;Variables a utilizar
 PSECT udata_bank0     ; common memory             
   W_TEMP:    DS 1     ; Variable temporal
   STAT_TEMP: DS 1     ; Variable temporal
   FLAG:      DS 1 
   BAN:       DS 1
   Bin:       DS 1
   SDISP:     DS 1
   FSOOSA:    DS 1     ; Flag para las operaciones
   NIBBLE:    DS 2     ; Número más y menos significativo
   DISP:      DS 2     ; Variable del display
   DIVISOR:   DS 3     ; Variable para la división
   NUMERO:    DS 3     ; Unidades, decenas, centenas

    
 ;------------------------ V E C T O R   R E S E T -----------------------------
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
 
 ORG 00h               ; Posición 0000h para el reset
 resetVec:
	PAGESEL main
	goto main
    
	
 ;---------------------- V E C T O R   I N T E R R U P T -----------------------
 
 ORG 004h               ; Posición 004 para la interrupción
 
 PUSH: 
    BCF   INTCON, 7     ; Desact. general interrupt (evitar interr. simultaneas)
    MOVWF W_TEMP        ; Guardar lo que se encuentra en w
    SWAPF STATUS, W     ; Guardar stat. a W sin MOVF (no afectar banderas de stat.)
    MOVWF STAT_TEMP     ; Guardar lo de W en variable temporal
     
ISR:                    ; (Interrupciones) chequear que la bandera está encendida
    BTFSC INTCON, 0     ; Bandera RBIF
    CALL  Button
    BTFSC INTCON, 2     ; Bandera TOIF 
    CALL  TIMER0 
      
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
    
TIMER0:
    BSF   FLAG, 2       ; Encender bandera de interrupción
    CALL  timer         ; Inicializar timer 
    CLRF  PORTC
    BTFSC BAN, 0        ; Skip it clear primer bit  
    goto  display1
    BTFSC SDISP, 0      ; Si esta encendida significa que la 2da bandera se encendió
    goto  display2
    BTFSC SDISP, 1
    goto  display3
    BTFSC SDISP, 2
    goto  display4
    
    
; Display Hexadecimal
display0:
    MOVF  DISP+0, w    ; Primer display
    movwf PORTD
    BSF   PORTC, 4
    goto  ProxD
    
display1:
    MOVF  DISP+1, w      ; Segundo display
    movwf PORTD
    BSF   PORTC, 3
    
ProxD:
    MOVLW 1             ; Negando el estado cuando = 1 pasa D
    XORWF BAN, F
    MOVF  PORTA
    BSF   SDISP, 0      ; Encender flag cuando se termine de hacer eso
    RETURN

display2:
    BCF   SDISP, 0
    MOVF  DIVISOR, w     ; Centenas
    MOVWF PORTD
    BSF   PORTC, 0
    BSF   SDISP, 1
    RETURN
    
display3: 
    BCF   SDISP, 1      ; Limpiar bandera de decenas
    MOVF  DIVISOR+1, w  ; Decenas
    MOVWF PORTD
    BSF   PORTC, 1
    BSF   SDISP, 2      ; Setear bandera de unidades
    RETURN
   
display4:
    MOVF  DIVISOR+2, w  ; Unidades
    MOVWF PORTD
    BSF   PORTC, 2
    CLRF  SDISP         ; Limpiar el byte
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
    RETLW  01110111B     ; A
    RETLW  01111100B     ; B
    RETLW  00111001B     ; C
    RETLW  01011110B     ; D
    RETLW  01111001B     ; E
    RETLW  01110001B     ; F
    
 
;---------------------- C O N F I G U R A C I O N E S --------------------------

main: 
    CALL    config_pines
    CALL    weak_PU
    CALL    Inicializar
    CALL    Interrupciones
    CALL    prescaler
    
    banksel OSCCON
    BSF     SCS            ; Utilizar oscilador interno
    call    timer          ; Inicializar el timer
    CLRF    W_TEMP         ; Inicializar las variables
    CLRF    STAT_TEMP 
    CLRF    FLAG  
    CLRF    BAN
    CLRF    Bin
    CLRF    NIBBLE
    CLRF    DISP 
    CLRF    SDISP 
    CLRF    DIVISOR
    CLRF    FSOOSA
    CLRF    NUMERO 
    banksel PORTA   
   
;-------------------------------- L O O P --------------------------------------
    
 loop: 
;   C O N T A D O R     
    BTFSC  FLAG, 0      ; Skip if clear, si no está apachado se hace la acción
    CALL   inc_A        ; Incrementar puerto A
    BTFSC  FLAG, 1      ; Skip if clear, si no está apachado se hace la acción
    CALL   dec_A        ; Decrementar el puerto A
    CALL   SPLIT 
    
    BTFSS  FSOOSA, 0	;Revisar bandera de terminar centenas
    CALL   CEN		
    BTFSS  FSOOSA, 1	;Revisar banderas de terminar decenas
    CALL   DECC
    BTFSS  FSOOSA, 2	;Revisar banderas de terminar unidades
    CALL   UN
    CALL   Displays
    goto   loop
    
;-------------------------- S U B R U T I N A ----------------------------------
;                               Etiquetas


; C O N F I G U R A C I O N E S 
config_pines:
    banksel ANSEL          ; Ir al registro donde está ANSEL
    CLRF    ANSEL          ; pines digitales
    CLRF    ANSELH         ; Puerto B digital  
         
    banksel TRISA          ; Ir al banco en donde está TRISA
    BSF     TRISB, 0       ; Pines = inputs
    BSF     TRISB, 1
    CLRF    TRISA          ; Puertos = outputs
    BCF     TRISC, 0
    BCF     TRISC, 1
    BCF     TRISC, 2
    BCF     TRISC, 3
    BCF     TRISC, 4
    CLRF    TRISD
    RETURN
 
;----------------------- W E A K   P U L L   U P -------------------------------
weak_PU:
    BCF     OPTION_REG, 7   ; Desabilitar el RBPU para utilizar pull up en dos p
    MOVLW   00000011B       ; Habilitar lo del IOCB en pines RB0 y RB1
    MOVWF   IOCB            ; Interrupt on change
    MOVWF   WPUB            ; Habilitar pull ups
    RETURN
    
Inicializar:
    banksel PORTA           ; Ir al banco donde está PORTA
    CLRF    PORTA           ; Inicializar los puertos
    CLRF    PORTB           
    CLRF    PORTC
    CLRF    PORTD
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
    
prescaler:
    BCF     PSA            ; Prescaler se le asigna al módulo TMR0
    CLRWDT                 ; Clear watch dog y prescalador
    banksel OPTION_REG     ; Ir al banco donde está Op. reg
    MOVLW   11010000B      ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W  ; Prescaler bit
    IORLW   00000100B      ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    RETURN

timer: 
    banksel TMR0           ; Ir al banco de TMR0
    MOVLW   6              ; Cargar N = 6 (viene de la ecuación de t)
    MOVF    TMR0           ; Moverlo a TMR0
    BCF     INTCON, 2      ; Bandera de overflow (viene con v desconocido)
    RETURN 
  
    
; C O N T A D O R 
inc_A:  
    CLRF   NUMERO          ; Limpiar contador
    CLRF   DIVISOR
    CLRF   Bin
    CLRF   FSOOSA
    INCF   PORTA, F        ; Si está en clear incrementa 1 en el puerto C
    CLRF   FLAG
    RETURN                 ; Regresar al loop
    
dec_A: 
    CLRF   NUMERO          ; Limpiar contador
    CLRF   DIVISOR
    CLRF   Bin
    CLRF   FSOOSA
    DECF   PORTA, F        ; Si está en clear incrementa 1 en el puerto B
    CLRF   FLAG
    RETURN                 ; Regresar al loop
    
; D I S P L A Y  H E X A D E C I M A L 
Displays: 
    BCF    FLAG, 2
    MOVF   NIBBLE, W       ; Bits menos significativos se muestran en 1er disp.
    CALL   Tabla
    MOVWF  DISP
    MOVF   NIBBLE+1, W     ; Bits más significativos se muestran en 2do disp.
    CALL   Tabla
    MOVWF  DISP+1
    
    ; D I S P L A Y  D E C I M A L 
    MOVF   NUMERO, W       ; Centenas
    CALL   Tabla
    MOVWF  DIVISOR         ; Guardar en variable las centenas
    
    MOVF   NUMERO+1, W     ; Decenas
    CALL   Tabla
    MOVWF  DIVISOR+1  
	
    MOVF   NUMERO+2, W     ; Unidades
    CALL   Tabla
    MOVWF  DIVISOR+2       ;Guardar en variable las unidades
    RETURN

SPLIT:
    MOVF   PORTA, w        ; El valor del puerto
    ANDLW  0x0f            ; And es para que se que queden los primeros bits
    MOVWF  NIBBLE          ; Se guarda el valor
    SWAPF  PORTA, w        ; Switchear el valor del puerto
    ANDLW  0x0f            ; Se quedan los bits más significativos
    MOVWF  NIBBLE+1        ; Se guarda en el segundo byte
    RETURN
    
    
;        R E S T A
;UNIDADES, DECENAS Y CENTENAS

UN: 
    MOVLW  1
    SUBWF  Bin, F        ; Restar 1 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   NUMERO+2      ; Incrementar unidades
    BTFSS  STATUS, 0 
    BSF    FSOOSA, 2     ; Apagar resta de unidades
    BTFSS  STATUS, 0
    ADDWF  Bin           ; Sumarle 1 
    RETURN
    
DECC:
    MOVLW  10
    SUBWF  Bin, F        ; Restar 10 y guardarlo en F
    BTFSC  STATUS, 0     ; Verificar si ocurrió un borrow
    INCF   NUMERO+1      ; Incrementar decenas
    BTFSS  STATUS, 0     ; Si carry = 1 no ha terminado de contar
    BSF	   FSOOSA, 1     ; Apagar resta de decenas
    BTFSS  STATUS, 0
    BCF    FSOOSA, 2     ; Encender resta de unidades
    BTFSS  STATUS, 0
    ADDWF  Bin           ; Sumar 10 al valor para no perder el numero
    RETURN

CEN:
    BSF   FSOOSA, 1      ; Apagar bandera de decenas y unidades
    BSF   FSOOSA, 2
    MOVF  PORTA, W 
    BTFSS FSOOSA, 3      ; Verificar si ya se copió una vez el valor de PORTA
    MOVWF Bin          
    BSF   FSOOSA, 3      ; No tomar de nuevo el valor de PORTA
    MOVLW 100
    SUBWF Bin, F         ; Restarle 100 y guardarlo en F
    BTFSC STATUS, 0      ; Chequear si se realizó un borrow
    INCF  NUMERO         ; Incrementar contador de centenas
    BTFSS STATUS, 0      ; Si carry = 1 no ha terminado de contar
    BSF	  FSOOSA, 0      ; Apagar resta de centenas
    BTFSS STATUS, 0
    BCF   FSOOSA, 1      ; Encender resta de decenas
    BTFSS STATUS, 0
    ADDWF Bin
    RETURN
    
END


