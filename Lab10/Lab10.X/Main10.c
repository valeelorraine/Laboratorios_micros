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

#define _XTAL_FREQ 4000000         // Frecuencia de operación

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
unsigned char DATO = 96;
unsigned char I[95] = "¿Que accion desea realizar?\r1) Desplegar cadena de caracteres\r2) Cambiar PORTA\r3) Cambiar PORTB";
int VALOR;
char PUERTOA;
char PUERTOB;

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);         // Configuraciones
void putch(char DATO);    // Dato que se desea transmitir
void INS(void);           // Mensaje a desplegar

//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************


//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************

void setup(void) {
    // Configuración de puertos
    ANSEL = 0X00;               // Pines digitales en el puerto A
    ANSELH = 0X00;              // Puerto B digital
    
    TRISA = 0x00;               // Puertos como outputs      
    TRISB = 0X00; 
    TRISCbits.TRISC6 = 0;       // RX entrada Y TX salida
    TRISCbits.TRISC7 = 1;       // RX entrada Y TX salida
    
    PORTA = 0X00;               // Inicializar los puertos
    PORTB = 0X00;
    
    // Configuración del oscilador
    OSCCONbits.SCS = 1;         // Utilizar el oscilador interno   
    INTCONbits.GIE = 1;         // GIE Encender interrupción de global
    INTCONbits.PEIE = 1;        // PEIE 
  
    OSCCONbits.IRCF2 = 1;       // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    
    // Configuración UART transmisor y receptor asíncrono
    PIR1bits.RCIF = 0;          // Bandera
    PIE1bits.RCIE = 1;          // Habilitar la interrución por el modo receptor
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
    setup();                    // Llamar al set up    
    while (1){
         __delay_ms(500); 
        VALOR = 0;
        if(VALOR > 94){
            TXREG = I[VALOR];
            VALOR++;
    }
        INS();                  // Llamar al mensaje a mostrar
    }
}

//******************************************************************************
//                           F U N C I O N E S
//******************************************************************************

void putch(char DATA){
    while(TXIF == 0){           // TXIF = 1 cuando no se está recibiendo nada   
        TXREG = DATA;           // Transmite datos al recibir printf en algun lado
    }
}

void INS(void){
    switch(RCREG){
        while(RCIF == 0){
            case 49:
                if (PIR1bits.TXIF == 1){
                    DATO++;            // Inc. var. para mandar cadena de caract.
                    if(DATO > 122){    // El alfabeto en minúsculas
                        DATO = 97;     // Empezar en a
                              }
                    TXREG = DATO;
                    TXREG = 32;        // Espacio
                }
                break;
                
            case 50:
                printf("\r Presione el caracter para desplegar en PORTA: \r");
                PUERTOA = RCREG;
                PORTA = PUERTOA;
                break;
                
            case 51:
                printf("\r Presione el caracter para desplegar en PORTB: \r");
                PUERTOB = RCREG;
                PORTB = PUERTOB; 
                break;
                
            default:
                NULL;
                break;
            
                        
        }  
    }
  }


               