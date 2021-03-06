/* 
 * File:   Main7.c (Laboratorio No. 7)
 * Author: Valerie Lorraine Sofia Valdez Trujillo
 * Compilador: pic-as (v2.30), MPLABX V5.45
 * 
 * Descripci�n del programa: 
 * 
 * Hardware: 4 servomotores, 1 joystick que incluye dos potenci�metros y un push
 *           luz led.
 * 
 * Created on 22 de mayo de 2021, 19:05
 */

//******************************************************************************
//                           L I B R E R � A S
//******************************************************************************
#include <xc.h>
#include <stdint.h>

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
#define _tmr0_value 176            // N = 176 para obtener un overflow de 0.08ms
#define _XTAL_FREQ 4000000         // Frecuencia de operaci�n
#define addressEEPROM 0X00

//******************************************************************************
//                           V A R I A B L E S
//******************************************************************************
uint8_t VAL;                       // Variable para los potenci�metros
uint8_t VAL1;                      // Variable para los potenci�metros
uint8_t VAL2;                      // Variable para los potenci�metros
uint8_t VAL3;                      // Variable para los potenci�metros
uint8_t PWM1;                      // Variable para el 1er PWM creado
uint8_t PWM2;                      // Variable para el 2do PWM creado
uint8_t POT3;                      // Variable para el 3er POT
uint8_t POT4;                      // Variable para el 4to POT
uint8_t val1;                      // Valor 1er modo
uint8_t val2;                      // Valor 2do modo
uint8_t val3;                      // Valor 3er modo
uint8_t val4;                      
uint8_t VALOR = 0;
uint8_t VALOR1;
uint8_t VALOR2;
uint8_t FLAG;                      // Bandera del UART
uint8_t OP;                        // Opci�n para desplegar mensaje
unsigned char I[72] = " \nBienvenido, presione 1 para continuar con la comunicacion serial\n";
unsigned char R[60] = " \nQue servomotor desea mover?\n1) PD \n2) PI \n3) CD \n4) CI\n";
unsigned char M[36] = " \nIngrese un numero entre 0 y 9\n";

//******************************************************************************
//                 P R O T O T I P O S  de  F U N C I O N E S
//******************************************************************************
void setup(void);                   // Configuraciones
void canales(void);                 // Switcheo de pots con servos
void escribir(uint8_t data, uint8_t address);
uint8_t leer(uint8_t address);
void UART(void);                    // Funci�n UART
void INS(void);                     // Mensajes a desplegar
void OTRO(void);                    
void MENSAJE(void);
void MTMR0(void);
//******************************************************************************
//                     F U N C I � N   para   I S R
//******************************************************************************
void __interrupt() isr(void){  
    if(PIR1bits.ADIF == 1){         //INTERRUPCI�N DEL ADC
        switch(ADCON0bits.CHS){     // Asignaci�n del ADRESH a las variables
            case 0:                 // Tambi�n es un switcheo con casos
                VAL = ADRESH;       
                break;
            case 1: 
                VAL1 = ADRESH; 
                break;
            case 2:
                VAL2 = ADRESH; 
                break;
            case 3:
                VAL3 = ADRESH; 
                break;
            }        
        PIR1bits.ADIF = 0;          // Limpiar bandera   
       }
        
    // INTERRUPCI�N DEL TIMER0
    if(INTCONbits.T0IF == 1){       // Bandera del TMR0 encendida
        PWM1++;                     // Incrementa el contador para el PWM del S1
        if(PWM1 <= POT3){           // El valor del per�odo depende del POT3    
            PORTCbits.RC3 = 1;      // Encender el pin
        }
        else{                       
            PORTCbits.RC3 = 0;      // Apagar el pin
        }
        if(PWM1 <= POT4){           // El valor del per�odo depende del POT4  
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
    
    
    // INTERRUPCI�N DEL PUERTO B
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
            PORTDbits.RD0 = 1;      // Encender pin para la led
            PORTDbits.RD1 = 0;      // Apagar el otro pin
            escribir(VALOR1, 0x10); // Funci�n de escritura de la EEPROM
            escribir(VALOR2, 0x11);
            escribir(POT3, 0X12);
            escribir(POT4, 0X13);
            __delay_ms(500);
        }
        if(PORTBbits.RB1 == 0){     // Presionado porque son pull ups
            ADCON0bits.ADON = 0;
            PORTDbits.RD0 = 0;      // Apagar el otro pin
            PORTDbits.RD1 = 1;      // Encender pin para la led
            val1 = leer(0X10);      // Funci�n de lectura de la EEPROM
            val2 = leer(0x11);
            val3 = leer(0x12);
            val4 = leer(0x13);
            
            CCPR1L = val1;          // Se igualan vals. para actualizar posic.
            CCPR2L = val2;
            POT3 = val3;
            POT4 = val4;
            __delay_ms(3000);
            ADCON0bits.ADON = 1;
        }
        INTCONbits.RBIF = 0;       // Limpiar la bandera del IOCB
    }
    PIR1bits.TMR2IF = 0;           // Limpiar la bandera del TMR2
}

//******************************************************************************
//                      C O N F I G U R A C I � N
//******************************************************************************
void setup(void){
    // CONFIGURACI�N DE LOS PUERTOS
    ANSEL = 0B00011111;        // Pines digitales en el puerto A
    ANSELH = 0X00;             // Puerto B digital
    
    TRISA = 0B00011111;        // Puertos como outputs   
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    TRISBbits.TRISB2 = 1;
    TRISC = 0B10000000;
    TRISD = 0B00; 
    
    PORTA = 0X00;              // Inicializar los puertos
    PORTB = 0X00;
    PORTC = 0X00;
    PORTD = 0X00;
    
    // WEAK PULL UP
    IOCB = 0xFF; 
    OPTION_REGbits.nRBPU = 0;   // Internal pull ups habilitados
    WPUB = 0B00000111;
    
    // Configuraci�n del TMR0, N = 176 y un overflow de 0.08ms
    OPTION_REG = 0B00001000;        
    TMR0 = _tmr0_value;         // Inicializar TMR0
    INTCONbits.GIE = 1;         // GIE Encender interrupci�n de global
    INTCONbits.PEIE = 1;        // PEIE 
    INTCONbits.T0IE = 1;        // T0IE Encender interrupci�n de OVERFLOW TMR0 
    INTCONbits.T0IF = 0;        // Limpiar la bandera del overflow TMR0
    INTCONbits.RBIE = 1;        // Interrupcion del iocb
    INTCONbits.RBIF = 0;        // Limpiar la bandera
    
    // Configuraci�n del oscilador, TMR2
    OSCCONbits.SCS = 1;         // Utilizar el oscilador itnterno
    OSCCONbits.IRCF2 = 1;       // Oscilador de 4MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    PIR1bits.TMR2IF = 0;        // Limpiar la bandera del TMR2
    T2CON = 0X26;               // Encender TMR2ON, Pre 1:16 y Post 1:5
   
    // Configuraciones del m�dulo ADC
    ADCON0bits.CHS = 0;         // Usar canal 0
    ADCON0bits.CHS = 2;         // Usar canal 2
    __delay_us(100);            // Delay de 100
    
    PIE1bits.ADIE = 1;          // ADIE Habilitar para comprobar FLAG -GF
    PIR1bits.ADIF = 0;          // Limpiar bandera de interrupci�n del ADC
    ADCON0bits.ADON = 1;        // Encender el m�dulo
    ADCON0bits.ADCS = 1;        // FOSC/8 
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       // Voltaje de referencia en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    // Configuraci�n del PWM
    PR2 = 250;                  // Per�odo del pwm 4ms
    CCP1CON = 0B00001100;       // El CCP1 se encuentra en Modo PWM 
    CCP2CON = 0B00001111;       // El CCP2 se encuentra en modoo PWM
    
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
    BAUDCTLbits.BRG16 = 0;      // Activar el generador de baudios
    SPBRG = 25;                 // Para una velocidad de transmisi�n de 9600
    SPBRGH = 1; 
    }

//******************************************************************************
//                         L O O P   P R I N C I P A L
//******************************************************************************
void main(void){  
    setup();                        // Llamar al set up       
    while (1){  
        canales();                  // Swicheo de los canales
       //UART();
    }
}
//******************************************************************************
//                           F U N C I O N E S 
//******************************************************************************
// Imprimir e mensaje en la terminal
void UART(void){ 
        __delay_ms(500); 
            VALOR = 0;
            do{VALOR++;                     // Incrementar la variable
                TXREG = I[VALOR];           // Desplegar los caracteres
                __delay_ms(50); 
            } 
            while(VALOR<=72);               // Cantidad de carcateres del Array
            while(RCIF == 0);
            INS();                          // Llamar al mensaje a mostrar )
 } 

// Bit banging se refiere a manejar el PWM por tiempos manuales
void canales(){                // Switcheo de los canales
    if(ADCON0bits.GO == 0){
        switch(ADCON0bits.CHS){           
            case 0: 
                CCPR1L = ((0.247*VAL)+62);  // Funci�n para el servo
                VALOR1 = CCPR1L;
                ADCON0bits.CHS = 1;         // Canal 2
                __delay_us(100);            // Delay para activar una medici�n
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break; 
                
            case 1:                         // PWM codificado
                POT4 = ((0.049*VAL1)+7);
                ADCON0bits.CHS = 2;         // Canal 0
                __delay_us(250);            // Delay para activar una medici�n
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break; 
                              
            case 2: 
                CCPR2L = ((0.247*VAL2)+62); // Funci�n para el servo
                VALOR2 = CCPR2L;
                ADCON0bits.CHS = 3;         // Canal 3
                __delay_us(100);            // Delay para activar una medici�n
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break; 
                
            case 3:                         // PWM codificado
                POT3 = ((0.049*VAL3)+7); 
                ADCON0bits.CHS = 0;         // Canal 1
                __delay_us(250);            // Delay para activar una medici�n
                ADCON0bits.GO = 1;          // Comienza el ciclo del ADC
                break; 
                
            default:
                break;
         }
    }
}

// Funci�n para escribir en la EEPROM
void escribir(uint8_t data, uint8_t address){ 
    EEADR = address;               // Direcci�n de mem. a la que se le va a escr.
    EEDAT = data;                  // Valor a escribir
   
    EECON1bits.EEPGD = 0;          // Apuntar a la data memory
    EECON1bits.WREN = 1 ;          // Habilitar escritura
    INTCONbits.GIE = 0;            // Apagar las interrupciones globales
    
    EECON2 = 0X55;                 // Secuencia necesaria para la escritura
    EECON2 = 0xAA;
    EECON1bits.WR = 1;             // Iniciar la escritura
    
    while(PIR2bits.EEIF == 0);     // Esperar al final de la escritura
    PIR2bits.EEIF = 0;             // Apagar la bandera
    EECON1bits.WREN = 0;           // Asegurar que no se est� escribiendo
    INTCONbits.GIE = 0;            // Habilitar las interrupciones globales
   }  

// Funci�n para leer de la EEPROM
uint8_t leer(uint8_t address){   
    EEADR = address;               // Ingresar direcci�n
    EECON1bits.EEPGD = 0;          // Apuntar a la PROGRAM MEM.
    EECON1bits.RD = 1;             // Indicar que se leer�
    uint8_t data = EEDATA;         // El dato permanece en la variable
    return data;                   // Recueprar el dato 
}
  
// Mensaje a desplegar
void INS(void){  
    OP = RCREG;
    switch(OP){
        case 49:                   // Si se presiona el #1 MANUALMENTE
            __delay_ms(500); 
            VALOR = 0;
            do{VALOR++;            // Incrementar la variable
                TXREG = R[VALOR];  // Desplegar cada caracter
                __delay_ms(50); 
            } 
            while(VALOR<=60);      // Cantidad de carcateres del Array
            while(RCIF == 0);
                OP = 0;            // Limpiar la variable que hace el cambio
                OTRO();
                break;  
        case 50:                   // Si se presiona el #2 COM. SERIAL
            TXSTAbits.TXEN = 0;    // Apagar la bandera de transmisi�n
            OP = 0;
            break;   
        }
}

void OTRO(void){                   // Funci�n para elegir servo a mover
    OP = RCREG;
    switch(OP){ 
        case 49:                   // Si se presiona #1
            MENSAJE();             // Desplegar mensaje
            if(RCREG >= 48 && RCREG <= 57){ 
                VAL = RCREG;       // Valor para el mapeo
                canales();
            }
            break;
        case 50:                   // Si se presiona #2
            MENSAJE();             // Desplegar mensaje
            if(RCREG >= 48 && RCREG <= 57){
                VAL1 = RCREG;      // Valor para el mapeo
                canales();
                }
            break;
        case 51:                    // Si se presiona #3
            MENSAJE();              // Desplegar mensaje
            if(RCREG >= 48 && RCREG <= 57){ 
                VAL2 = RCREG;       // Valor para el mapeo
                canales();
            }
            break;
        case 52:                    // Si se presiona #4
            MENSAJE();              // Desplegar mensaje
            if(RCREG >= 48 && RCREG <= 57){ 
                VAL3 = RCREG;       // Valor para el mapeo
                canales();
            }
            break; 
     }
 }

void MENSAJE(void){
    __delay_ms(500); 
    VALOR = 0;
    do{VALOR++;                    // Incrementar la variable
    TXREG = M[VALOR];              // Desplegar cada caracter
    __delay_ms(50); 
    } 
    while(VALOR<=36);              // Cantidad de carcateres del Array
    while(RCIF == 0);
    OP = 0;                        // Limpiar la variable que hace el cambio
    }

