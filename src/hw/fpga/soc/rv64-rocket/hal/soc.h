#ifndef SOC_H
#define SOC_H

/* UART */
#define UART_BASE	  0x70600000
#define UART_RX         	0x00
#define UART_TX         	0x04
#define UART_STAT       	0x08
#define UART_CTRL       	0x0C

/* GPIO */
#define GPIO_BASE  	  0x70000000
#define GPIO_DATA           0x00
#define GPIO_CTRL           0x01

/* BRAM */
#define BRAM_BASE  	  0x60000000

void uart_init();
int  putchar(int c);
void putstr(char * str);
void puthex(unsigned int tp);
void puthex64(unsigned long long int tp);

#endif /* SOC_H */
