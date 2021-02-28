; ------------------------------------------------------------------------------
;                         Identificación del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripción del programa: contador binario de 4 bits con 2 push buttons que 
;           utilicen interrupciones ON-CHANGE, pull ups internos, 4 LEDs y un 
;           display para mostrar el valor del contador. Asimismo, implementar un 
;           contador que utilice la interrupción del TMR0 la cual deberá ser en-
;           tre 5 y 20ms, pero el contador deberá cambiar CADA 1000ms, mostrar 
;           valor en display.
    
; Hardware: 2 push buttons en el puerto B, 4 LEDs en el puerto A, un dislay en
;           el puerto C y el otro en el puerto D.
    
; Creado: 22/02
; Última modificación: 27/02
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
 CONFIG LVP=OFF             // Progra en bajo voltaje permitido
 
;configuración word 2
 CONFIG WRT=OFF             // Protección de autoescritura por prog. descativada
 CONFIG BOR4V=BOR40V        // Reinicio a bajo de 4v, (BOR21V=2.1V)
 
;Variables a utilizar
 PSECT udata_bank0          ; common memory       
   FLAG: DS 1               ; 1 BYTE
   COUNTER: DS 1            ; Contador 1 bYTE
   W_TEMP: DS 1             ; Variable temporal
   STAT_TEMP: DS 1          ; Variable temporal
   DISP: DS 1
   
    
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
    
 ;----------------------------- Vector reset -----------------------------------

 ORG 00h                    ;posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main
    
 ;--------------------------- Vector Interrupt ---------------------------------
 ORG 004h ;Posición 004
 
 PUSH: 
    BCF   INTCON, 7   ; Desact. interrupciones para evitar interr. simultaneas 
    MOVWF W_TEMP      ; Guardar lo que se encuentra en w
    SWAPF STATUS, W   ; Guardar STATUS a W sin usar MOVF (osea afectar las banderas de status)
    MOVWF STAT_TEMP   ; Guardar lo de W en variable temporal
    
 ISR:                 ; (Interrupciones) chequear que la bandera está encendida
    BTFSC INTCON, 0   ; Bandera RBIF
    CALL  Button
    BTFSC INTCON, 2   ; Bandera TOIF
    CALL  INC  
      
 POP: 
    SWAPF STAT_TEMP, W ; Regresando el valor al original
    MOVWF STATUS       ; Regresarlo a STATUS
    SWAPF W_TEMP, F    ; darle vuelta a los nibbles de Wtemp
    SWAPF W_TEMP, W    ; Regresamos al orden original y guardamos en w
    RETFIE             ; Regresar de la interrupción (incluye reactivacion del GIE) 
    
Button: 
    BTFSS PORTB, 0     ; Revisar 1er pin del PORTB
    BSF   FLAG, 0      ; Setear FLAG
    BTFSS PORTB, 1     ; Revisar 2do pin del PORTB
    BSF   FLAG, 1
    BCF   INTCON, 0    ; Limpiar FLAG RBIF
    RETURN
    
INC:
    BSF   FLAG, 2      ; Setear bandera
    BCF   INTCON, 2    ; Limpiar bandera del STATUS
    RETURN 
    
;Configuración del microcontrolador
 PSECT code, delta=2, abs   ; A partir de acá es código
 ORG 0100h                  ;posición para el código
 
 ; D I S P L A Y
 
Tabla:
    CLRF   PCLATH 
    BSF    PCLATH, 0    ; Limpiar program counter
    ADDWF  PCL, 1       ; retlw regresa un valor de W cargado
    RETLW  00111111B    ; 0
    RETLW  00000110B    ; 1
    RETLW  01011011B    ; 2
    RETLW  01001111B    ; 3
    RETLW  01100110B    ; 4
    RETLW  01101101B    ; 5
    RETLW  01111101B    ; 6
    RETLW  00000111B    ; 7
    RETLW  01111111B    ; 8
    RETLW  01100111B    ; 9
    RETLW  01110111B    ; A
    RETLW  01111100B    ; B
    RETLW  00111001B    ; C
    RETLW  01011110B    ; D
    RETLW  01111001B    ; E
    RETLW  01110001B    ; F
    
 
;----------------------- C O N F I G U R A C I Ó N -----------------------------
 
main: 
    banksel ANSEL           ; Ir al registro donde está ANSEL
    clrf    ANSEL           ; pines digitales
    clrf    ANSELH          ; Puerto B digital  
        
    banksel TRISA           ; Ir al banco en donde está TRISA
    BSF     TRISB, 0        ; Pines = inputs
    BSF     TRISB, 1
    CLRF    TRISA           ; PUERTOS = OUTPUTS
    CLRF    TRISC
    CLRF    TRISD

;   W E A K   P U L L   U P
    
    BCF     OPTION_REG, 7   ; Desabilitar el RBPU para utilizar pull up en dos p
    MOVLW   00000011B       ; Habilitar lo del IOCB en pines RB0 y RB1
    MOVWF   IOCB
    MOVWF   WPUB            ; Habilitar pull ups
    
    banksel PORTA           ; Ir al banco donde está PORTA
    CLRF    PORTA
    CLRF    PORTB           ; Inicializar los puertos
    CLRF    PORTC
    CLRF    PORTD
  
    banksel INTCON
    BSF     INTCON, 3       ; Encender interrupción de PORTB
    BCF     INTCON, 5       ; Encender interrupción de TMR0
    BSF     INTCON, 7       ; Encender interrupción de global
    BCF     INTCON, 2
    banksel PORTA
        
    
;             E C U A C I Ó N     T E M P O R I Z A D O R
;               Tosc 1 = contador y Tosc = 0 temporizador
    
; D O N D E: 
;           Temporización : 4*TOSC*TMR0*Prescaler (predivisor)
;           TOSC = 1/FOSC
;           TMR0 = 256-N (valor a cargar en TMR0)
   
    CLRWDT                  ; Clear watch dog y prescalador
    banksel OPTION_REG      ; Ir al banco donde está Op. reg
    MOVLW   11010000B       ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W   ; Prescaler bit
    IORLW   00000100B       ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    
    banksel OSCCON
    BSF     SCS             ; Utilizar oscilador interno
    call    timer           ; Inicializar el timer
   
   
;-------------------------------- L O O P --------------------------------------
    
 loop: 
    
;   C O N T A D O R     
    BTFSC  FLAG, 0   ; Bit test skip if clear, si no está apachado se hace la acción
    call   inc_A     ; Incrementar puerto A
    BTFSC  FLAG, 1   ; Bit test skip if clear, si no está apachado se hace la cción
    call   dec_A     ; Decrementar el puerto A

;   T E M P O R I Z A D O R
    BTFSC  FLAG, 2       ; Si Flag = 0 Ejecutar sigiente instr.
    CALL TIMER0
    goto   loop
    
;-------------------------- S U B R U T I N A ----------------------------------
;                               Etiquetas
    
    
 TIMER0:
    CALL    timer
    INCF    COUNTER      ; Incrementar contador
    BCF     INTCON, 2    ; Limpiar la bandera
    MOVLW   125
    SUBWF   COUNTER, 0    ; 0 se guarda en w
    BTFSS   ZERO
  ; BTFSC  STATUS, 2     ; STATUS = 1 Ejecutar siguiente instr.
    RETURN
    CLRF    COUNTER  
    call    temporizador
   RETURN
    
    

timer: 
    banksel TMR0         ; Ir al banco de TMR0
    MOVLW   6            ; Cargar N = 6 (viene de la ecuación de t)
    MOVF    TMR0         ; Moverlo a TMR0
    BCF     INTCON, 2    ; Bandera de overflow (viene con v desconocido)
    RETURN 
    
    
; T E M P O R I Z A D O R 
    
temporizador: 
    
    DECF    DISP, 1      ; Incrementar el temporizador
    BCF     STATUS, 2    ; Limpiar el 2do bit de STATUS
    MOVF    DISP, W
    ANDLW   0X0F
    CALL    Tabla
    MOVWF   PORTD
    RETURN 
    
inc_counter:
    INCF    COUNTER      ; Incrementar contador
    BCF     INTCON, 2    ; Limpiar la bandera 
    RETURN
 
; C O N T A D O R 
    
inc_A:  
    INCF  PORTA, F  ; Si está en clear incrementa 1 en el puerto C
    BTFSC PORTA, 4  ; Revisar valor del 4t bit
    CLRF  PORTA     ; Resetear si 4to bit = 1
    MOVF  PORTA, 0
    CALL  Tabla 
    MOVWF PORTC
    CLRF  FLAG      ; Limpiar bandera
    RETURN          ; Regresar al loop
    
dec_A: 
    DECF  PORTA, F  ; Si está en clear incrementa 1 en el puerto B
    MOVLW 0x0F      ; Cargar valor a W cuando se decrementa de 0 a F hex
    BTFSC PORTA, 7  ; Revisar valor del 4t bit
    MOVWF PORTA
    MOVF  PORTA, 0  ; Cargar W en el puerto para encender 4 bit
    CALL  Tabla
    MOVWF PORTC
    CLRF  FLAG      ; Limpiar bandera
    RETURN          ; Regresar al loop
    
END