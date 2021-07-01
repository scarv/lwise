#include "soc.h"

//! UART registers
static volatile int unsigned * uart_rx  = (volatile int unsigned*)(UART_BASE+UART_RX);
static volatile int unsigned * uart_tx  = (volatile int unsigned*)(UART_BASE+UART_TX);
static volatile int unsigned * uart_stat= (volatile int unsigned*)(UART_BASE+UART_STAT);
static volatile int unsigned * uart_ctrl= (volatile int unsigned*)(UART_BASE+UART_CTRL);
static char hexchar[16]= "0123456789ABCDEF";
void uart_init() {
    
    // Enable the UART module. Disable interrupts and reset both FIFOs.
    *uart_ctrl = 0x3;
}

//! Write a character to serial port.
int  putchar(char c){
    // Wait until the TX FIFO is not full
    unsigned int  full = *uart_stat & (0x1<<3);
    while(full) { full = *uart_stat & (0x1<<3);  }

    // Write the byte to the TX FIFO of the UART.
    unsigned int to_write = 0 | (unsigned int) c;
    *uart_tx = to_write;
}

//! Write a string to a stream with no trailing '\n' character.
void putstr(char * str){
	int i=0;
	while (str[i] !=0) {
		putchar(str[i]);
		i++;
	}
}
//! Write a hexadecimal representation of a 32-bit number to serial port.
void puthex(unsigned int tp){
	for(int i=0;i<8;i++){
		char c = hexchar[((tp & 0xF0000000)>>28)];
		putchar(c);
		tp <<=4;		
	}
}

//! Write a hexadecimal representation of a 64-bit number to serial port.
void puthex64(unsigned long long int tp) {
    unsigned int a = tp & 0xFFFFFFFF;
    unsigned int b = (tp >> 32) & 0xFFFFFFFF;
    puthex(b);
    puthex(a);
}
