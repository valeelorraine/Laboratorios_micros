/* 
 * File:   Main7.c (Laboratorio No. 7)
 * Author: Valerie Lorraine Sofia Valdez Trujillo
 * Compilador: pic-as (v2.30), MPLABX V5.45
 * 
 * Descripci�n del programa: 
 * 
 * Hardware: 
 *
 * Created on 18 de abril de 2021, 20:28
 */

//******************************************************************************
//                           L I B R E R � A S
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <xc.h>


//******************************************************************************
//                      C O N F I G U R A C I � N 
//******************************************************************************

// PIC16F887 Configuration Bit Settings
#pragma config FOSC=INTRC_NOCLKOUT // Oscillador interno I/O RA6
#pragma config WDTE=OFF            // WDT disabled (reinicio rep. del pic)
#pragma config PWRTE=OFF           // Power-up Timer (PWRT disabled)
#pragma config MCLRE=OFF           // El pin de MCLR se utiliza como I/O
#pragma config CP=OFF              // Sin protecci�n de c�digo
#pragma config CPD=OFF             // Sin protecci�n de datos

#pragma config BOREN=OFF           // No reinicia cu�ndo Vin baja de 4v
#pragma config IESO=OFF            // Reinicio sin cambio de reloj inter-exter.
#pragma config FCMEN=OFF           // Cambio de reloj exter-inter en caso falla
#pragma config LVP=OFF             // Progra en bajo voltaje permitido

// CONFIG2
#pragma config BOR4V = BOR40V      // Reinicio a bajo de 4v, (BOR21V=2.1V)
#pragma config WRT = OFF           // Protecci�n de autoescritura x prog. desact.

//******************************************************************************
//             D I R E C T I V A S  del  C O M P I L A D O R
//******************************************************************************

#define _XTAL_FREQ 4000000         // Frecuencia de operaci�n

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
unsigned char DATO[21] = " \rVamos a sacar 100\r";
unsigned char I[96] = " Que accion desea realizar?\r1) Desplegar cadena de caracteres\r2) Cambiar PORTA\r3) Cambiar PORTB\r";
int VALOR = 0;
int VALOR1 = 0;
int OP;

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);         // Configuraciones
void INS(void);           // Mensaje a desplegar


//******************************************************************************
//                      C O N F I G U R A C I � N
//******************************************************************************

void setup(void) {
    // Configuraci�n de puertos
    ANSEL = 0X00;               // Pines digitales en el puerto A
    ANSELH = 0X00;              // Puerto B digital
    
    TRISA = 0x00;               // Puertos como outputs      
    TRISB = 0X00; 
    TRISCbits.TRISC6 = 0;       // RX entrada Y TX salida
    TRISCbits.TRISC7 = 1;       // RX entrada Y TX salida
    
    PORTA = 0X00;               // Inicializar los puertos
    PORTB = 0X00;
    
    // Configuraci�n del oscilador
    OSCCONbits.SCS = 1;         // Utilizar el oscilador interno   
    INTCONbits.GIE = 1;         // GIE Encender interrupci�n de global
    INTCONbits.PEIE = 1;        // PEIE 
  
    OSCCONbits.IRCF2 = 1;       // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    
    // Configuraci�n UART transmisor y receptor as�ncrono
    PIR1bits.RCIF = 0;          // Bandera
    PIE1bits.RCIE = 0;          // Habilitar la interruci�n por el modo receptor
    PIE1bits.TXIE = 0;          // Habilitar bandera de interrupci�n
    TXSTAbits.TX9 = 0;          // 8 bits
    TXSTAbits.TXEN = 1;         // Se habilita el transmisor
    TXSTAbits.SYNC = 0;         // Se opera de forma as�ncrona y de 8 bits
    TXSTAbits.BRGH = 1; 
    RCSTAbits.RX9 = 0;          // 8 bits
    RCSTAbits.CREN = 1;         // Receptor se habilita
    RCSTAbits.SPEN = 1;         // M�dulo ON y el pin TX se config. como salida
                                // y el RX como entrada

    // Generador de baudios del USART
    BAUDCTLbits.BRG16 = 0;
    SPBRG = 25;                  // Para una velocidad de transmisi�n de 9600
    SPBRGH = 1; 
    }

//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************

void main(void){  
    setup();                     // Llamar al set up    
    while (1){
            __delay_ms(500); 
            VALOR = 0;
            do{VALOR++;          // Incrementar la variable
                TXREG = I[VALOR];   
                __delay_ms(50); 
            } 
            while(VALOR<=95);     // Cantidad de carcateres del Array
            while(RCIF == 0);
            INS();                // Llamar al mensaje a mostrar  
            }
    }

//******************************************************************************
//                           F U N C I O N E S
//******************************************************************************

void INS(void){  
    OP = RCREG;
    switch(OP){
            case 49:                       // Si presionan 1
                do{VALOR1++;               // Incrementar variable
                TXREG = DATO[VALOR1];      // Mostrar caracter
                __delay_ms(50); 
            } 
                while(VALOR1<=21);
                 VALOR1 = 0;              // Limpiar la variable que hace el cambio
                 OP = 0;
                break;
                
            case 50:                      // Si presionan 2
                 __delay_ms(500);
                while(RCIF == 0);         // Esperar a ingresar caracter
                PORTA = RCREG;            // El valor ingresado estar� en PORTA
                OP = 0;                   // Limpiar la variable que hace el cambio
                break;
                
            case 51:                      // Si presionan 3
                __delay_ms(50);  
                while(RCIF == 0);         // Esperar a ingresar caracter
                PORTB = RCREG;            // El valor ingresado estar� en PORTB
                OP = 0;                   // Limpiar la variable que hace el cambio
                break;
        }
     }
      
