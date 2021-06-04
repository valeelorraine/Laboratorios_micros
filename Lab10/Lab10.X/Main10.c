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
                PORTA = RCREG;            // El valor ingresado estará en PORTA
                OP = 0;                   // Limpiar la variable que hace el cambio
                break;
                
            case 51:                      // Si presionan 3
                __delay_ms(50);  
                while(RCIF == 0);         // Esperar a ingresar caracter
                PORTB = RCREG;            // El valor ingresado estará en PORTB
                OP = 0;                   // Limpiar la variable que hace el cambio
                break;
        }
     }
      

//sdnjksd
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
#include <PIC16F887.h>
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
#define addressEEPROM 0X00

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
uint8_t VAL;                       // Variable para los potenciómetros
uint8_t PWM1;                      // Variable para el 1er PWM creado
uint8_t PWM2;                      // Variable para el 2do PWM creado
uint8_t POT3;                      // Variable para el 3er POT
uint8_t POT4;                      // Variable para el 4to POT
uint8_t RX;
uint8_t modo;                     // Variable para la EEPROM LECTURA
uint8_t modos;                     // Variable para la EEPROM ESCRITURA
uint8_t val1;                      // Valor 1er modo
uint8_t val2;                      // Valor 2do modo
uint8_t val3;                      // Valor 3er modo
char guardar = 103;                // g en ASCII
char rep = 114;                    // r en ASCII

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);
void canales(uint8_t VAL);
void escribir(uint8_t data, uint8_t address);
uint8_t leer(uint8_t address);
void play(void);
void record(void);

//******************************************************************************
//                     F U N C I Ó N   para   I S R
//******************************************************************************
void __interrupt() isr(void){  
    if(PIR1bits.ADIF == 1){         // Interrupción del ADC
        VAL = ADRESH;               // Asignarle valor de ADRESH a la variable
        PIR1bits.ADIF = 0;          // Limpiar bandera 
        }

    if(PIR1bits.RCIF == 1){         // EUSART Receive Interrupt Flag bit = 1
        RX = RCREG;                 // Guardar el valor recibido
        }
    
//Contador de 300
    if(INTCONbits.T0IF == 1){       // Bandera del TMR0 encendida
        PWM1++;                     // Incrementa el contador para el PWM del S1
        
        if(PWM1 <= POT3){           // El valor del período depende del POT3    
            PORTCbits.RC3 = 1;      // Encender el pin
        }
        else{                       
            PORTCbits.RC3 = 0;      // Apagar el pin
        }
        
        if(PWM1 <= POT4){           // El valor del período depende del POT4  
        //    TMR0 = POT3;
            PORTCbits.RC4 = 1;      // Encender el pin
        }
        else{
            PORTCbits.RC4 = 0;      // Apagar el pin
        }
        
        if(PWM1 >= 250){            // Si se cumplen los 20ms reiniciar variable
            PWM1 = 0;
        }
        
        TMR0 = _tmr0_value;         // Inicializar TMR0
        INTCONbits.T0IF = 0;        // Limpiar bandera del TMR0
        } 
        PIR1bits.TMR2IF = 0;        // Limpiar la bandera del TMR2
    }

//******************************************************************************
//                      C O N F I G U R A C I Ó N
//******************************************************************************
void setup(void){
    // Configuración de puertos
    ANSEL = 0B00011111;          // Pines digitales en el puerto A
    ANSELH = 0X00;               // Puerto B digital
    
    TRISA = 0B00011111;          // Puertos como outputs   
    TRISB = 0B00000011;
    TRISC = 0X00; 
    TRISD = 0X00; 
    TRISCbits.TRISC6 = 0;       // RX entrada Y TX salida
    TRISCbits.TRISC7 = 1;       // RX entrada Y TX salida
    
    PORTA = 0X00;                // Inicializar los puertos
    PORTB = 0X00;
    PORTC = 0X00;
    PORTD = 0X00;
    
    //Configuración de
    
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
    BAUDCTLbits.BRG16 = 0;      // Activar el generador de baudios
    SPBRG = 25;                 // Para una velocidad de transmisión de 9600
    SPBRGH = 1; 
    }

//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************
void main(void){  
    setup();                            // Llamar al set up       
    while (1){  
        canales(VAL);                   // Switcheo de canales
        if(RX == guardar){              
            record();
        }
        if(RX == rep){
            play();
        }
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
                ADCON0bits.CHS = 1;       // Canal 2
                __delay_us(100);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                
            case 1:                       // PWM codificado
                POT4 = ((0.049*VAL)+7);
                PORTD = POT4;
                ADCON0bits.CHS = 2;       // Canal 0
                __delay_us(250);          // Delay para activar una medición
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
                ADCON0bits.CHS = 0;       // Canal 1
                __delay_us(250);          // Delay para activar una medición
                ADCON0bits.GO = 1;        // Comienza el ciclo del ADC
                break; 
                
            default:
                break;
         }
    }
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
    INTCONbits.GIE = 1;         // Habilitar las interrupciones globales
   }   

//// Función para leer de la EEPROM
//uint8_t leer(uint8_t address){   
//    EEADR = address;             // Ingresar dirección
//    EECON1bits.EEPGD = 0;        // Apuntar a la PROGRAM MEM.
//    EECON1bits.RD = 1;           // Indicar que se leerá
//    uint8_t data = EEDATA;       // El dato permanece en la variable
//    return data;                 // Recueprar el dato 
//}


void play(void){
    RX = 0; 
    switch(modo){
        case 0:
            escribir(0x00, val1);
            escribir(0x01, val2);
            escribir(0x02, val3);
            modos = 1;
            break; 
        case 1:
            escribir(0x03, val1);
            escribir(0x04, val2);
            escribir(0x05, val3);
            modos = 2;
            break;
            
        case 2:
            escribir(0x06, val1);
            escribir(0x07, val2);
            escribir(0x08, val3);
            modos = 0;
            break;
    }
}
//    
//void record(void){
//    RX = 0;
//    switch(modos){
//        case 0:
//            escribir(0x00, val1);
//            escribir(0x01, val2);
//            escribir(0x02, val3);
//            modos = 1;
//            break; 
//        case 1:
//            escribir(0x03, val1);
//            escribir(0x04, val2);
//            escribir(0x05, val3);
//            break;
//            
//        case 2:
//            escribir(0x06, val1);
//            escribir(0x07, val2);
//            escribir(0x08, val3);
//            break;
//    }   
//}  