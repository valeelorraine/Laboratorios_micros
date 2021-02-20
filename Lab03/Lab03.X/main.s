; ------------------------------------------------------------------------------
;                         Identificación del documento
; ------------------------------------------------------------------------------
; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Valerie Valdez
; Copilador: pic-as (v2.30), MPLABX V5.45

; Descripción del programa: oscilador utilizado como temporizador, contador bi-
;           nario de 4 bits con display que aumente y decremente con pushes. 
;           Cuando t = c LED se enciende y se reinicia el uC.
    
; Hardware:En los pines RA0 Y RA1 están conectados dos push buttons mientras que
;          en el RA3 se conectó el LED que presenta la alarma. Por otro lado, en
;          el puerto B se encuentran los LEDS para el temporizador y en el D el
;          display para el contador.
    
; Creado: 15/02
; Última modificación: 19/02
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
   COUNTER: DS 1            ; Contador 1 bit 
    
;Instrucciones del vector de reset
 PSECT resVect, class=CODE, abs, delta=2   ;(cant. de bytes para usar instr)
    
 ;----------------------------- Vector reset -----------------------------------
 ORG 00h                    ;posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main
    
;Configuración del microcontrolador
 PSECT code, delta=2, abs   ; A partir de acá es código
 ORG 0100h                   ;posición para el código
 
;----------------------- C O N F I G U R A C I Ó N -----------------------------
 
main: 
    banksel ANSEL           ; Ir al registro donde está ANSEL
    clrf    ANSEL           ; pines digitales
    clrf    ANSELH          ; Puerto B digital  
    
    banksel TRISA           ; Ir al banco en donde está TRISA
    BSF     TRISA, 0        ; Pines = inputs
    BSF     TRISA, 1
    BCF     TRISA, 3        ; Output
    CLRF    TRISB           ; Pines = outputs
    CLRF    TRISC
    CLRF    TRISD


    banksel PORTA           ; Ir al banco donde está PORTA
    CLRF    PORTA
    CLRF    PORTB           ; Inicializar los puertos
    CLRF    PORTC
    CLRF    PORTD
    
; Tosc 1 = contador y Tosc = 0 temporizador
; Temporización : 4*TOSC*TMR0*Prescaler (predivisor)
    ; TOSC = 1/FOSC
    ; TMR0 = 256-N (valor a cargar en TMR0)
    
    CLRWDT                  ; Clear watch dog y prescalador
    banksel OPTION_REG      ; Ir al banco donde está Op. reg
    MOVLW   11010000B       ; Cargar los valores y TOCS bit 5 = 0
    ANDWF   OPTION_REG, W   ; Prescaler bit
    IORLW   00000100B       ; Set prescale to 1:32
    MOVWF   OPTION_REG 
    
    banksel OSCCON
    BSF     OSCCON, 4       ; Setear para colocar la frecuencia en 8Mhz
    BSF     OSCCON, 5      
    BSF     OSCCON, 6
    BSF     SCS             ; Utilizar oscilador interno
    
    call    timer           ; Inicializar el timer
    
;-------------------------------- L O O P --------------------------------------
;                           Boton presionado = 1
; Prescaler es para que cuente mas lento algo asi como un divisor de frec.
    
 loop: 
    
;    C O N T A D O R 
    
    btfsc  PORTA, 0      ; Bit test, skip it if clear. f = 1 ejecuta sig. instr.
    call   antirrebote   ; Llamar etiqueta 
    btfss  PORTA, 0      ; Bit test f, skip it if set. f = 0 ejecuta sig. instr
    call   inc_C         ; Llamar al incremento
    btfsc  PORTA, 1      ; Repetir procedimiento para incremento y decremento
    call   antirrebote1  
    btfss  PORTA, 1
    call   dec_C
    call   Tabla 
    movwf  PORTD, F
    
;  T E M P O R I Z A D O R 
    
    btfss  INTCON, 2     ; Bit test, f = 0 ejecutar sig. instr.
    goto   $-1 
    call   timer
    MOVLW  250
    SUBWF  COUNTER, 0    ; 0 se guarda en w
    BTFSC  STATUS, 2     ; STATUS = 1 Ejecutar siguiente instr.
    call   temporizador
    call   inc_counter
    
;  A L A R M A
    
    MOVF   PORTB, W
    SUBWF  PORTC, 0      ; Se guarda en w
    BTFSC  STATUS, 2     ; STATUS = 1 Ejecutar siguiente instr.
    call   overflow
    goto   loop          ; Regresar al loop
    
;-------------------------- S U B R U T I N A ----------------------------------
;                               Etiquetas
   
timer: 
    banksel TMR0         ; Ir al banco de TMR0
    MOVLW   131          ; Cargar N = 131 (viene de la ecuación de t)
    MOVF    TMR0         ; Moverlo a TMR0
    BCF     INTCON, 2    ; Bandera de overflow (viene con v desconocido)
    RETURN 
    
; T E M P O R I Z A D O R 
    
temporizador: 
    INCF    PORTB, F     ; Incrementar el temporizador
    BTFSC   PORTB, 4     ; Revisar valor del 4to bit
    CLRF    PORTB        ; Resetear si 4to bit = 1
    BCF     STATUS, 2    ; Limpiar el 2do bit de STATUS
    RETURN 
    
inc_counter:
    INCF    COUNTER      ; Incrementar contador
    BCF     INTCON, 2    ; Limpiar la bandera 
    RETURN

; D I S P L A Y
    
Tabla:
    CLRF   PCLATH 
    BSF    PCLATH, 0     ; Limpiar program counter
    MOVWF  PORTC, W
    ADDWF  PCL, F        ; retlw regresa un valor de W cargado
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
    
; C O N T A D O R
    
antirrebote: 
    BSF   FLAG, 0   ; Bit set, si se presionó enciende el 1er bit de la FLAG
    RETURN          ; Si Flag != 1 entonces regresa al Loop
    
inc_C:  
    BTFSS FLAG, 0   ; Bit test skip if set, si no está apachado se hace la acción
    RETURN          ; Si está en clear se regresa al loop 
    INCF  PORTC, F  ; Si está en set incrementa 1 en el puerto C
    BTFSC PORTC, 4  ; Revisar valor del 4t bit
    CLRF  PORTC     ; Resetear si 4to bit = 1
    CLRF  FLAG      ; Limpiar bandera
    RETURN          ; Regresar al loop
   
antirrebote1: 
    BSF   FLAG, 1   ; Bit set, si se presionó enciende el 2do bit de la FLAG
    RETURN          ; Si Flag != 1 entonces regresa al Loop
    
dec_C: 
    BTFSS FLAG, 1   ; Bit test skip if set, si no está apachado se hace lacción
    RETURN          ; Si está en clear se regresa al loop 
    DECF  PORTC, F  ; Si está en set incrementa 1 en el puerto B
    MOVLW 0x0F      ; Cargar valor a W cuando se decrementa de 0 a F hex
    BTFSC PORTC, 4  ; Revisar valor del 4t bit
    MOVWF PORTC     ; Cargar W en el puerto para encender 4 bit
    CLRF  FLAG      ; Limpiar bandera
    RETURN          ; Regresar al loop
 
overflow:
    MOVLW 0x08      ; Encender el 4to bit
    XORWF PORTA, F  ; XOR AL RA3, c/activacion cambia el valor ALARMA CAMBIAR VALOR
    CLRF  PORTB     ; Resetear portb
    BCF   STATUS, 2 ; Limpiar el 2do bit de STATUS
    RETURN
    
END





