/* 
 * File:   Main7.c (Laboratorio No. 7)
 * Author: Valerie Lorraine Sofia Valdez Trujillo
 * Compilador: pic-as (v2.30), MPLABX V5.45
 * 
 * Descripción del programa: Contador que funciona con la interrupci{on del TMR0
 *                           Contador que incrementa y decrementa con dos pushes
 *                           Ambos muestran sus valores en 8 LEDS, sin embargo
 *                           el contador de pushes tambien muestra su valor en 3
 *                           displays multiplexados.
 * 
 * Hardware: 2 Push buttons conectados a RB0 y RB1 con WPU 
 *           16 Leds conectados al puerto A y C
 *           3 displays multiplexados en el puerto D con sus transistores 
 *           conectados a los 3 pines del puerto E.
 * 
 * Created on 12 de abril de 2021, 17:56
 * Última modificación:
 */

//******************************************************************************
//                       Importación de librerías
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <xc.h>

//******************************************************************************
//                           Configuración  
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
//                        Directivas del compilador
//******************************************************************************

#define _tmr0_value 100            // N de 100 para obtener un overflow de 5ms

//******************************************************************************
//                             Variables
//******************************************************************************
unsigned char FLAG;                // Variable para incrementar el contador
unsigned char FLAGS;               // Variable para decrementar el contador
unsigned char DISPLAY = 1;         // Variable para la multiplexación
unsigned char CENTENAS;           
unsigned char DECENAS;
unsigned char UNIDADES;
unsigned char VAL;

//******************************************************************************
//                          Valores del display
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
//                       Prototipos de funciones
//******************************************************************************
void setup(void);
void VALORES(void);

// Función para el ISR
void __interrupt() isr(void){   
    
    if(T0IF == 1){               // Bandera del TMR0 encendida
       INTCONbits.T0IF = 0;      // Apagar la bandera
       PORTA++;                  // Incrementar contador del TMR0
       TMR0 = _tmr0_value;       // Inicializar TMR0
       
       switch(DISPLAY){          // Multiplexación de los DISPLAYS
        case 1:                  // Centenas buscan el valor en la tabla
            PORTE = 0X00;
            PORTD = NUMEROS[CENTENAS]; 
            PORTEbits.RE0 = 1;   // Encender pin del transistor del disp
            DISPLAY++;           // Incrementar variable para ir al sig. display
            break;
        case 2:                  // Decenas buscan el valor en la tabla
            PORTE = 0X00;
            PORTD = NUMEROS[DECENAS];
            PORTEbits.RE1 = 1;   // Encender pin del transistor del disp
            DISPLAY++;           // Incrementar variable para ir al sig. display
            break;
        case 3:                  // Unidades buscan el valor en la tabla
            PORTE = 0X00;
            PORTD = NUMEROS[UNIDADES];
            PORTEbits.RE2 = 1;   // Encender pin del transistor del disp
            DISPLAY = 1;         // Regresar al primer display
            break;
        }
       INTCONbits.T0IF = 0;      // Apagar la bandera
                 } 
    
    if(INTCONbits.RBIF == 1){    // Si RBIF se enciende...                     
        if(PORTBbits.RB0 == 0){  // Si RB0 se presionó y soltó, encender FLAG 
            FLAG = 1;}           
        else{
            if(FLAG == 1){       // Si la flag está encendida entonces apagarla
                FLAG = 0;        
                PORTC++;         // Incrementar el puerto
            }     
        }
        if(PORTBbits.RB1 == 0){  // Si RB1 se presionó y soltó, encender FLAGS
            FLAGS = 1;
        }
        else{
            if(FLAGS == 1){      // Si FLAGS está encendida entonces apagarla
                FLAGS = 0;
                PORTC--;         // Decrementar el puerto
            }
        }
        INTCONbits.RBIF = 0;     // RBIF Limpiar la bandera de CHANGE INTERRUPT
    }
}

//******************************************************************************
//                         Configuración
//******************************************************************************

void setup(void) {
    // Configuración de puertos
    ANSEL = 0X00;               // pines digitales
    ANSELH = 0X00;              // Puerto B digital
    
    TRISA = 0X00;               // Puertos como outputs
    TRISC = 0X00; 
    TRISD = 0X00; 
    TRISE = 0X00;
    TRISB = 0B00000011;         // RB0 y RB1 son inputs
    
    PORTA = 0X00;               // Inicializar los puertos
    PORTB = 0X00;
    PORTC = 0X00;
    PORTD = 0X00;
    PORTE = 0X00;
    
    // WEAK PULL UP
    IOCB = 0B00000011;          // Habilitar lo del IOCB en pines RB0 y RB1
    WPUB = 0B00000011;
            
    OPTION_REG = 0B01010100;    // Prescaler en 32
            
            
    // Configuración del oscilador y TMR0
    OSCCONbits.SCS = 1;         // Utilizar el oscilador itnterno
    OPTION_REGbits.nRBPU = 0;   // Desabilitar RBPU para utilizar pullUp en 2 Pa
      
    INTCONbits.GIE = 1;         // GIE Encender interrupción de global
    INTCONbits.RBIE = 1;        // RBIE Encender interrupción PORTB CHANGE
    INTCONbits.T0IE = 1;        // T0IF Limpiar la bandera del TMR0
    INTCONbits.RBIF = 0;        // RBIF Limpiar la bandera de CHANGE INTERRUPT
    INTCONbits.T0IF = 0;        // T0IE Encender interrupción de OVERFLOW TMR0 
    }
    
    
    //**************************************************************************
    //                         Loop principal
    //**************************************************************************
void main(void){  
    setup();                   // Llamar al set up
    
    while (1){ 
        VAL = PORTC;           // La variable empieza con el valor del puerto C
        VALORES();   }         // Llamar a la función
    }

void VALORES(void){            // División para obtener los valores del disp.
    CENTENAS = VAL/100;        
    VAL = VAL-CENTENAS*100;    // Quitarle las centenas
    DECENAS = VAL/10;
    VAL = VAL-DECENAS*10;      // Quitarle decenas
    UNIDADES = VAL;            // Lo que sobra son unidades
        }
 
    