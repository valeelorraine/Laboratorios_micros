/* 
 * File:   Main7.c (Laboratorio No. 7)
 * Author: Valerie Lorraine Sofia Valdez Trujillo
 * Compilador: pic-as (v2.30), MPLABX V5.45
 * 
 * Descripción del programa: 
 * 
 * Hardware: 4 servomotores, 1 joystick que incluye dos potenciómetros y un push
 *           luz led.
 * 
 * Created on 22 de mayo de 2021, 19:05
 */

//******************************************************************************
//                           L I B R E R Í A S
//******************************************************************************
#include <xc.h>
#include <stdint.h>

//******************************************************************************
//                      C O N F I G U R A C I Ó N 
//******************************************************************************

// PIC16F887 Configuration Bit Settings
#pragma config FOSC=INTRC_NOCLKOUT // Oscillador interno I/O RA6
#pragma config WDTE=OFF            // WDT disabled (reinicio rep. del pic)
#pragma config PWRTE=OFF           // Power-up Timer (PWRT disabled)
#pragma config MCLRE=OFF           // El pin de MCLR se utiliza como I/O
#pragma config CP=OFF              // Sin protección de código
#pragma config CPD=OFF             // Sin protección de datos

#pragma config BOREN=OFF           // No reinicia cuándo Vin baja de 4v
#pragma config IESO=OFF            // Reinicio sin cambio de reloj inter-exter.
#pragma config FCMEN=OFF           // Cambio de reloj exter-inter en caso falla
#pragma config LVP=OFF             // Progra en bajo voltaje permitido

// CONFIG2
#pragma config BOR4V = BOR40V      // Reinicio a bajo de 4v, (BOR21V=2.1V)
#pragma config WRT = OFF           // Protección de autoescritura x prog. desact.

//******************************************************************************
//             D I R E C T I V A S  del  C O M P I L A D O R
//******************************************************************************
#define _XTAL_FREQ 4000000         // Frecuencia de operación
#define addressEEPROM 0X00

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
uint8_t VAL;                       // Variable para los potenciómetros
uint8_t VAL1;                      // Variable para los potenciómetros
uint8_t VAL2;                      // Variable para los potenciómetros
uint8_t VAL3;                      // Variable para los potenciómetros
uint8_t PWM1;                      // Variable para el 1er PWM creado
uint8_t PWM2;                      // Variable para el 2do PWM creado
uint8_t val1;                      // Valor 1er modo
uint8_t val2;                      // Valor 2do modo
uint8_t val3;                      // Valor 3er modo
uint8_t val4;
uint8_t VALOR = 0;
uint8_t VALOR1;
uint8_t VALOR2;
uint8_t FLAG;
uint8_t OP;
unsigned char I[85] = " \rComo desea controlar los servomotores?\r1) Manualmente \r2) Con comunicacion serial\r";
unsigned char R[60] = " \rQue servomotor desea mover?\r1) PD \r2) PI \r3) CD \r4) CI\r";
unsigned char M[36] = " \rIngrese un numero entre 0 y 9\r";

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);
void escribir(uint8_t data, uint8_t address);
uint8_t leer(uint8_t address);
void UART(void);
void INS(void);                     // Mensaje a desplegar
void OTRO(void);
void MENSAJE(void);
void servo11(void);
void servo12(void);
void servo13(void);
void servo21(void);
void servo22(void);
void servo23(void);
//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************
void __interrupt() isr(void){  
    if(PIR1bits.ADIF == 1){         //INTERRUPCIÓN DEL ADC
        if(ADCON0bits.GO == 0){
        switch(ADCON0bits.CHS){     // Asignación del ADRESH a las variables
            case 0:                 // También es un switcheo con casos
                VAL = ADRESH;   
                CCPR1L = ((0.247*VAL)+62);  // Función para el servo
                VALOR1 = CCPR1L;
                ADCON0bits.CHS = 1;         // Canal 2
                __delay_us(100);            // Delay para activar una medición
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break;
                
            case 1: 
                VAL1 = ADRESH; 
                if(VAL1<=85){
                    servo11();
                }
                if((VAL1>=86) && (VAL1<=170)){
                    servo12();
                       } 
                if(VAL1>=171){
                    servo13();
                       } 
                ADCON0bits.CHS = 2;         // Canal 0
                __delay_us(250);            // Delay para activar una medición
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break;
                
            case 2:
                VAL2 = ADRESH; 
                CCPR2L = ((0.247*VAL2)+62); // Función para el servo
                VALOR2 = CCPR2L;
                ADCON0bits.CHS = 3;         // Canal 3
                __delay_us(100);            // Delay para activar una medición
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break;
                
            case 3:
                VAL3 = ADRESH; 
                if(VAL3<=85){
                    servo21();
                }
                if((VAL3>=86) && (VAL3<=170)){
                    servo22();
                       } 
                if(VAL3>=171){
                    servo23();
                       } 
                ADCON0bits.CHS = 0;         // Canal 1
                __delay_us(250);            // Delay para activar una medición
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break;
            }      
        } 
        PIR1bits.ADIF = 0;          // Limpiar bandera   
       }
    
    // INTERRUPCIÓN DEL PUERTO B
    if(INTCONbits.RBIF == 1){ 
        if(PORTBbits.RB2 == 0){
            FLAG = 1;               // aCTIVAR BANDERA DEL UART
            while(FLAG == 1){
                TXSTAbits.TXEN = 1; 
                UART();
        }
            TXSTAbits.TXEN = 0; 
            }
        
        if(PORTBbits.RB0 == 0){     // Presionado porque son pull ups
            PORTDbits.RD0 = 1;
            PORTDbits.RD1 = 0;
            escribir(VALOR1, 0x10);
            escribir(VALOR2, 0x11);
            escribir(VAL1, 0X12);
            escribir(VAL3, 0X13);
            __delay_ms(500);
        }
        if(PORTBbits.RB1 == 0){     // Presionado porque son pull ups
            ADCON0bits.ADON = 0;
            PORTDbits.RD0 = 0;
            PORTDbits.RD1 = 1;
            val1 = leer(0X10);
            val2 = leer(0x11);
            val3 = leer(0x12);
            val4 = leer(0x13);
            
            CCPR1L = val1;
            CCPR2L = val2;
            VAL1 = val3;
            VAL3 = val4;
            __delay_ms(3000);
            ADCON0bits.ADON = 1;
        }
        INTCONbits.RBIF = 0;    // Limpiar la bandera del IOCB
    }
    
    PIR1bits.TMR2IF = 0;        // Limpiar la bandera del TMR2
}

//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************
void setup(void){
    // CONFIGURACIÓN DE LOS PUERTOS
    ANSEL = 0B00011111;        // Pines digitales en el puerto A
    ANSELH = 0X00;             // Puerto B digital
    
    TRISA = 0B00011111;        // Puertos como outputs   
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    TRISBbits.TRISB2 = 1;
    TRISC = 0X00;
    TRISD = 0B00; 
    
    PORTA = 0X00;              // Inicializar los puertos
    PORTB = 0X00;
    PORTC = 0X00;
    PORTD = 0X00;
    
    // WEAK PULL UP
    IOCB = 0xFF; 
    OPTION_REGbits.nRBPU = 0;   // Internal pull ups habilitados
    WPUB = 0B00000111;
    
    // Configuración del TMR0, N = 176 y un overflow de 0.08ms        
    INTCONbits.GIE = 1;         // GIE Encender interrupción de global
    INTCONbits.PEIE = 1;        // PEIE 
    INTCONbits.RBIE = 1;        // Interrupcion del iocb
    INTCONbits.RBIF = 0;        // Limpiar la bandera
    
    // Configuración del oscilador, TMR2
    OSCCONbits.SCS = 1;         // Utilizar el oscilador itnterno
    OSCCONbits.IRCF2 = 1;       // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    PIR1bits.TMR2IF = 0;        // Limpiar la bandera del TMR2
    T2CON = 0X26;               // Encender TMR2ON, Pre 1:16 y Post 1:5
   
    // Configuraciones del módulo ADC
    ADCON0bits.CHS = 0;         // Usar canal 0
    ADCON0bits.CHS = 2;         // Usar canal 2
    __delay_us(100);            // Delay de 100
    
    PIE1bits.ADIE = 1;          // ADIE Habilitar para comprobar FLAG -GF
    PIR1bits.ADIF = 0;          // Limpiar bandera de interrupción del ADC
    ADCON0bits.ADON = 1;        // Encender el módulo
    ADCON0bits.ADCS = 1;        // FOSC/8 
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       // Voltaje de referencia en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    // Configuración del PWM
    PR2 = 250;                  // Período del pwm 4ms
    CCP1CON = 0B00001100;       // El CCP1 se encuentra en Modo PWM 
    CCP2CON = 0B00001111;       // El CCP2 se encuentra en modoo PWM
    
    // Configuración UART transmisor y receptor asíncrono
    PIR1bits.RCIF = 0;          // Bandera
    PIE1bits.RCIE = 0;          // Habilitar la interrución por el modo receptor
    PIE1bits.TXIE = 0;          // Habilitar bandera de interrupción
    TXSTAbits.TX9 = 0;          // 8 bits
    TXSTAbits.TXEN = 1;         // Se habilita el transmisor
    TXSTAbits.SYNC = 0;         // Se opera de forma asíncrona y de 8 bits
    TXSTAbits.BRGH = 1; 
    RCSTAbits.RX9 = 0;          // 8 bits
    RCSTAbits.CREN = 1;         // Receptor se habilita
    RCSTAbits.SPEN = 1;         // Módulo ON y el pin TX se config. como salida
                                // y el RX como entrada

    // Generador de baudios del USART
    BAUDCTLbits.BRG16 = 0;      // Activar el generador de baudios
    SPBRG = 25;                 // Para una velocidad de transmisión de 9600
    SPBRGH = 1; 
    }

//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************
void main(void){  
    setup();                        // Llamar al set up       
    while (1){  
    }
}
//******************************************************************************
//                           F U N C I O N E S 
//******************************************************************************
// Imprimir e mensaje en la terminal
void UART(void){ 
        __delay_ms(500); 
            VALOR = 0;
            do{VALOR++;          // Incrementar la variable
                TXREG = I[VALOR];   
                __delay_ms(50); 
            } 
            while(VALOR<=95);     // Cantidad de carcateres del Array
            while(RCIF == 0);
            INS();                // Llamar al mensaje a mostrar )
 }

// Función para escribir en la EEPROM
void escribir(uint8_t data, uint8_t address){ 
    EEADR = address;            // Dirección de mem. a la que se le va a escribir
    EEDAT = data;               // Valor a escribir
   
    EECON1bits.EEPGD = 0;       // Apuntar a la data memory
    EECON1bits.WREN = 1 ;       // Habilitar escritura
    INTCONbits.GIE = 0;         // Apagar las interrupciones globales
    
    EECON2 = 0X55;              // Secuencia necesaria para la escritura
    EECON2 = 0xAA;
    EECON1bits.WR = 1;          // Iniciar la escritura
    
    while(PIR2bits.EEIF == 0);  // Esperar al final de la escritura
    PIR2bits.EEIF = 0;          // Apagar la bandera
    EECON1bits.WREN = 0;        // Asegurar que no se está escribiendo
    INTCONbits.GIE = 0;         // Habilitar las interrupciones globales
   }  

// Función para leer de la EEPROM
uint8_t leer(uint8_t address){   
    EEADR = address;            // Ingresar dirección
    EECON1bits.EEPGD = 0;       // Apuntar a la PROGRAM MEM.
    EECON1bits.RD = 1;          // Indicar que se leerá
    uint8_t data = EEDATA;      // El dato permanece en la variable
    return data;                // Recueprar el dato 
}
  
// Mensaje a desplegar
void INS(void){  
    OP = RCREG;
    switch(OP){
            case 49:                      // Si se presiona el #1 MANUALMENTE
                TXSTAbits.TXEN = 0;       // Apagar la bandera de transmisión
                OP = 0;
                break;   
            case 50:                      // Si se presiona el #2 COM. SERIAL
                    __delay_ms(500); 
                    VALOR = 0;
                    do{VALOR++;          // Incrementar la variable
                        TXREG = R[VALOR];   
                        __delay_ms(50); 
                    } 
                    while(VALOR<=60);    // Cantidad de carcateres del Array
                        while(RCIF == 0);
                    OP = 0;               // Limpiar la variable que hace el cambio
                    OTRO();
                    break;  
        }
}   

void MENSAJE(void){
    __delay_ms(500); 
    VALOR = 0;
    do{VALOR++;          // Incrementar la variable
    TXREG = M[VALOR];   
    __delay_ms(50); 
    } 
    while(VALOR<=36);    // Cantidad de carcateres del Array
    while(RCIF == 0);
    OP = 0;              // Limpiar la variable que hace el cambio
    }

void servo11(void){
        PORTCbits.RC3 = 1; 
        __delay_ms(0.7);
        PORTCbits.RC3 = 0; 
        __delay_ms(19.3);            // Cumplir con el periodo de 20ms
    }

void servo12(void){
        PORTCbits.RC3 = 1; 
        __delay_ms(1.5);
        PORTCbits.RC3 = 0; 
        __delay_ms(18.5);            // Cumplir con el periodo de 20ms
    }

void servo13(void){
        PORTCbits.RC3 = 1; 
        __delay_ms(2);             // Maximo a tener
        PORTCbits.RC3 = 0; 
        __delay_ms(18);            // Cumplir con el periodo de 20ms
    }

void servo21(void){
        PORTCbits.RC4 = 1; 
        __delay_ms(0.7);
        PORTCbits.RC4 = 0; 
        __delay_ms(19.3);            // Cumplir con el periodo de 20ms
    }

void servo22(void){
        PORTCbits.RC4 = 1; 
        __delay_ms(1.5);
        PORTCbits.RC4 = 0; 
        __delay_ms(18.5);            // Cumplir con el periodo de 20ms
    }

void servo23(void){
        PORTCbits.RC4 = 1; 
        __delay_ms(2);             // Maximo a tener
        PORTCbits.RC4 = 0; 
        __delay_ms(18);            // Cumplir con el periodo de 20ms
    }