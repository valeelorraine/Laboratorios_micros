/* 
 * File:   Main7.c (Laboratorio No. 7)
 * Author: Valerie Lorraine Sofia Valdez Trujillo
 * Compilador: pic-as (v2.30), MPLABX V5.45
 * 
 * Descripción del programa: 
 * 
 * Hardware: 
 *
 * Created on 18 de abril de 2021, 20:28
 */

//******************************************************************************
//                           L I B R E R Í A S
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <xc.h>

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

#define _tmr0_value 100            // N de 100 para obtener un overflow de 5ms
#define _XTAL_FREQ 4000000         // Frecuencia de operación

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
unsigned char DISPLAY = 1;         // Variable para la multiplexación
int CENTENAS;           
int DECENAS;
int UNIDADES;
int VAL;


//******************************************************************************
//                    V A L O R E S  del  D I S P L A Y
//******************************************************************************

char NUMEROS[10] = { 
    0B00111111,    // 0
    0B00000110,    // 1
    0B01011011,    // 2
    0B01001111,    // 3
    0B01100110,    // 4
    0B01101101,    // 5
    0B01111101,    // 6
    0B00000111,    // 7
    0B01111111,    // 8
    0B01100111,    // 9
    };

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************

void setup(void);
void VALORES(unsigned int);

//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************

void __interrupt() isr(void){   
   if(T0IF == 1){                // Bandera del TMR0 encendida
       INTCONbits.T0IF = 0;      // Apagar la bandera
       TMR0 = _tmr0_value;       // Inicializar TMR0
       
       switch(DISPLAY){          // Multiplexación de los DISPLAYS
        case 1:                  // Centenas buscan el valor en la tabla
            PORTE = 0X00;
            PORTC = NUMEROS[CENTENAS]; 
            PORTEbits.RE0 = 1;   // Encender pin del transistor del disp
            DISPLAY++;           // Incrementar variable para ir al sig. display
            break;
        case 2:                  // Decenas buscan el valor en la tabla
            PORTE = 0X00;
            PORTC = NUMEROS[DECENAS];
            PORTEbits.RE1 = 1;   // Encender pin del transistor del disp
            DISPLAY++;           // Incrementar variable para ir al sig. display
            break;
        case 3:                  // Unidades buscan el valor en la tabla
            PORTE = 0X00;
            PORTC = NUMEROS[UNIDADES];
            PORTEbits.RE2 = 1;   // Encender pin del transistor del disp
            DISPLAY = 1;         // Regresar al primer display
            break;
        }
        INTCONbits.T0IF = 0;     // Apagar la bandera
                 } 
   if(PIR1bits.ADIF == 1){ 
       if(ADCON0bits.CHS == 0){  // Revisar si el canal AN0 está activo
           PORTB = ADRESH;}
       else{
           VAL = ADRESH;}
   
   PIR1bits.ADIF = 0;           // Limpiar bandera 
   }
}

//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************

void setup(void) {
    // Configuración de puertos
    ANSEL = 0B00000101;         // pines digitales
    ANSELH = 0X00;              // Puerto B digital
    
    TRISA = 0B00000101;         // Puertos como outputs
    TRISB = 0X00;        
    TRISC = 0X00; 
    TRISE = 0X00;
    
    PORTA = 0X00;               // Inicializar los puertos
    PORTB = 0X00;
    PORTC = 0X00;
    PORTE = 0X00;
    
    OPTION_REG = 0B11010100;    // Prescaler en 32
    
    // Configuraciones del módulo ADC
    ADCON0bits.ADON = 1;        // Encender el módulo
    ADCON0bits.CHS = 2;
    __delay_us(100);            //Delay de 100
   
    ADCON0bits.ADCS = 1;        // FOSC/8 
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       // Voltaje de referencia
    ADCON1bits.VCFG1 = 0;
    
    // Configuración del oscilador, TMR0 y ADC
    OSCCONbits.SCS = 1;         // Utilizar el oscilador itnterno
    OSCCONbits.IRCF2 = 1;       // 4Mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    
    INTCONbits.GIE = 1;         // GIE Encender interrupción de global
    INTCONbits.T0IE = 1;        // T0IF Limpiar la bandera del TMR0
    INTCONbits.T0IF = 0;        // T0IE Encender interrupción de OVERFLOW TMR0 
    INTCONbits.PEIE = 1;        // PEIE 
    PIE1bits.ADIE = 1;          // ADIE Habilitar para comprobar FLAG -GF
    PIR1bits.ADIF = 0;          // Limpiar bandera de interrupción del ADC
    }

    
//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************

void main(void){  
    setup();                    // Llamar al set up
    ADCON0bits.GO = 1;          // Activar la secuencia de lectura
    
    while (1){         

        if (ADCON0bits.GO == 0){ // Como 
            if(ADCON0bits.CHS == 0){ 
                ADCON0bits.CHS = 2;
                }
            else{ 
                ADCON0bits.CHS = 0;
            }
            __delay_us(100);     // Delay previo a activar una medición
            ADCON0bits.GO = 1;
        }
        VALORES(VAL); 
    }          
}

//******************************************************************************
//                          F U N C I O N E S 
//******************************************************************************

void VALORES(unsigned int arg1){             // División para obtener los valores del disp.
    unsigned int temp;
    temp = arg1;
    CENTENAS = temp/100;        
    temp = temp-CENTENAS*100;     // Quitarle las centenas
    DECENAS = temp/10;
    temp = temp-DECENAS*10;       // Quitarle decenas
    UNIDADES = temp;             // Lo que sobra son unidades
        }
 
    

