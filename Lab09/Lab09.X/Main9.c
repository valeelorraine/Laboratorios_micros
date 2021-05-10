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
int VAL1;
int VAL2;

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);

//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************

void __interrupt() isr(void){   
   if(PIR1bits.ADIF == 1){       // Si la bandera del
       if(ADCON0bits.CHS == 0){  // Revisar si el canal AN0 está activo
           VAL1 = ADRESH;       
           CCPR1L = ((0.247*VAL1)+62); // Función para el servo
            }
       else{
           VAL2 = ADRESH;
           CCPR2L = ((0.247*VAL2)+62); // Función para el servo
           }
       
        PIR1bits.ADIF = 0;       // Limpiar bandera 
    }
}

//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************

void setup(void) {
    // Configuración de puertos
    ANSEL = 0B00000101;         // Pines digitales en el puerto A
    ANSELH = 0X00;              // Puerto B digital
    
    TRISA = 0B00000101;         // Puertos como outputs      
    TRISC = 0X00; 

    PORTA = 0X00;               // Inicializar los puertos
    PORTC = 0X00;
    
    // Configuración del oscilador, TMR2
    OSCCONbits.SCS = 1;         // Utilizar el oscilador itnterno
    OSCCONbits.IRCF2 = 1;       // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    PIR1bits.TMR2IF = 0;        // Limpiar la bandera del TMR2
    T2CON = 0X26;               // Encender TMR2ON, Pre 1:16 y Post 1:5
    
    INTCONbits.GIE = 1;         // GIE Encender interrupción de global
    INTCONbits.PEIE = 1;        // PEIE 
    PIE1bits.ADIE = 1;          // ADIE Habilitar para comprobar FLAG -GF
    PIR1bits.ADIF = 0;          // Limpiar bandera de interrupción del ADC
    
    // Configuraciones del módulo ADC
    ADCON0bits.CHS = 0;         // Usar canal 1
    ADCON0bits.CHS = 2;         // Usar canal 1
    __delay_us(100);            // Delay de 100
    
    ADCON0bits.ADON = 1;        // Encender el módulo
    ADCON0bits.ADCS = 1;        // FOSC/8 
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       // Voltaje de referencia en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    // Configuración del PWM
    PR2 = 250;                  // Periodo del pwm 4ms
    CCP1CON = 0B00001100;       // Modo PWM 
    CCP2CONbits.CCP2M0 = 1;
    CCP2CONbits.CCP2M1 = 1;
    CCP2CONbits.CCP2M2 = 1;
    CCP2CONbits.CCP2M3 = 1;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;    
    }

//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************

void main(void){  
    setup();                    // Llamar al set up       
    while (1){
       if(ADCON0bits.CHS == 0){  // Revisar si el canal AN0 está activo
           ADCON0bits.CHS = 2;   // Canal 2
           __delay_us(1000);     // Delay para activar una medición
           ADCON0bits.GO = 1;    
            }
       else{
           ADCON0bits.CHS = 0;    // Canal 0
           __delay_us(1000);      // Delay para activar una medición
           ADCON0bits.GO = 1;     
       }
         
    }
}



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
unsigned char OP[16] = "Ingrese un caracter\r";
int VALOR;

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);

//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************

void __interrupt() isr(void){   
    if(PIR1bits.RCIF == 1){   
        //PORTA = RCREG; Esto es para que losss leds tengan valor
        VALOR = RCREG;   // Asignar un valor a una variable
        
    }
  }

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

        if(TXIF == 1){
            if(VALOR <= 94){
                //TXREG = I[VALOR];
                VALOR++;
            }
            else{
                if(RCIF == 1){
                    VALOR = RCREG;
                }
            }
        }
    }
}


//******************************************************************************
//                           F U N C I O N E S
//******************************************************************************

switch(OP)
                // if (PIR1bits.TXIF == 1){
             //DATO++;            // Inc. la variable para mandar cadena de caract.
             
             
            //if(DATO > 122){    // El alfabeto en minúsculas
              // DATO = 97;      // Empezar en a
          //  }
           // TXREG = DATO;
            //TXREG = 32;
          //HACER SWITCH CASEEEEEE PARA CASOS DONDE SE ELIJA 1, 2, 3
      //  }