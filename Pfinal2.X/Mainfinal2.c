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
#define _tmr0_value 176            // N = 176 para obtener un overflow de 0.08ms
#define _XTAL_FREQ 4000000         // Frecuencia de operación

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
uint8_t VAL;                       // Variable para los potenciómetros
uint8_t POT3;
uint8_t PWM1; // cambiarla a 16
uint8_t POT4;
uint8_t PWM2;

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);
//void contadores(void);
void canales(uint8_t VAL);
//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************

void __interrupt() isr(void){  
    if(PIR1bits.ADIF == 1){  
        VAL = ADRESH;
        PIR1bits.ADIF = 0;          // Limpiar bandera 
        }

//Contador de 300
    if(INTCONbits.T0IF == 1){       // Bandera del TMR0 encendida
        PWM1++;                     // Incrementa el contador para el PWM del S1
        
        if(PWM1 <= POT3){           // El valor del período depende del POT3    
        //    TMR0 = POT3;
            PORTCbits.RC3 = 1; 
        }
        else{
            PORTCbits.RC3 = 0;
        }
        
        if(PWM1 <= POT4){
        //    TMR0 = POT3;
            PORTCbits.RC4 = 1; 
        }
        else{
            PORTCbits.RC4 = 0;
        }
        
        if(PWM1 >= 250){
           // TMR0 = POT3;
            PWM1 = 0;
        }
        
        TMR0 = _tmr0_value;      // Inicializar TMR0
        INTCONbits.T0IF = 0;            // Apagar la bandera
        } 
        PIR1bits.TMR2IF = 0;            // Limpiar la bandera del TMR2
    }


//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************

void setup(void){
    // Configuración de puertos
    ANSEL = 0B00011111;          // Pines digitales en el puerto A
    ANSELH = 0X00;               // Puerto B digital
    
    TRISA = 0B00011111;          // Puertos como outputs      
    TRISC = 0X00; 
    TRISD = 0X00; 
    TRISCbits.TRISC6 = 0;       // RX entrada Y TX salida
    TRISCbits.TRISC7 = 1;       // RX entrada Y TX salida
    
    PORTA = 0X00;                // Inicializar los puertos
    PORTC = 0X00;
    
    // Configuración del TMR0 con PRESCALER 1:1, N = 176 y un overflow de 0.08ms
    OPTION_REG = 0x88;          
    TMR0 = _tmr0_value;           // Inicializar TMR0
    INTCONbits.GIE = 1;           // GIE Encender interrupción de global
    INTCONbits.PEIE = 1;          // PEIE 
    INTCONbits.T0IE = 1;          // T0IE Encender interrupción de OVERFLOW TMR0 
    INTCONbits.T0IF = 0;          // Limpiar la bandera del overflow TMR0
    
    // Configuración del oscilador, TMR2
    OSCCONbits.SCS = 1;          // Utilizar el oscilador itnterno
    OSCCONbits.IRCF2 = 1;        // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    PIR1bits.TMR2IF = 0;         // Limpiar la bandera del TMR2
    T2CON = 0X26;                // Encender TMR2ON, Pre 1:16 y Post 1:5
   
    // Configuraciones del módulo ADC
    ADCON0bits.CHS = 0;          // Usar canal 0
    ADCON0bits.CHS = 2;          // Usar canal 2
    __delay_us(100);             // Delay de 100
    
    PIE1bits.ADIE = 1;           // ADIE Habilitar para comprobar FLAG -GF
    PIR1bits.ADIF = 0;           // Limpiar bandera de interrupción del ADC
    ADCON0bits.ADON = 1;         // Encender el módulo
    ADCON0bits.ADCS = 1;         // FOSC/8 
    ADCON1bits.ADFM = 0;         // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;        // Voltaje de referencia en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    // Configuración del PWM
    PR2 = 250;                   // Período del pwm 4ms
    CCP1CON = 0B00001100;        // El CCP1 se encuentra en Modo PWM 
    CCP2CON = 0B00001111;        // El CCP2 se encuentra en modoo PWM
    
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
    BAUDCTLbits.BRG16 = 0;
    SPBRG = 25;                  // Para una velocidad de transmisión de 9600
    SPBRGH = 1; 
    }
//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************

void main(void){  
    setup();                            // Llamar al set up       
    while (1){  
        canales(VAL);
    }
}
//******************************************************************************
//                           F U N C I O N E S 
//******************************************************************************

// Bit banging se refiere a manejar el PWM por tiempos manuales
void canales(uint8_t VAL){                // Switcheo de los canales
    if(ADCON0bits.GO == 0){
        switch(ADCON0bits.CHS){           
            case 0: 
                CCPR1L = ((0.247*VAL)+62);// Función para el servo
                ADCON0bits.CHS = 2;       // Canal 2
                __delay_us(100);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                          
            case 2: 
                CCPR2L = ((0.247*VAL)+62);// Función para el servo
                ADCON0bits.CHS = 3;       // Canal 3
                __delay_us(100);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                
            case 3:                       // PWM codificado
                POT3 = ((0.049*VAL)+7);
              //  PORTD = POT3;
                ADCON0bits.CHS = 1;       // Canal 4
                __delay_us(250);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                
            case 1:                      // PWM codificado
                POT4 = ((0.049*VAL)+7);
                PORTD = POT4;
                ADCON0bits.CHS = 0;       // Canal 0
                __delay_us(250);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                
            default:
                break;
         }
    }
}