#include "soc.h"
#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <limits.h>
#include <sys/signal.h>

#define static_assert(cond) switch(0) { case 0: case !!(long)(cond): ; }

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

#undef putchar
//! Write a character to serial port.
int  putchar(int c){
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


size_t strnlen(const char *s, size_t n)
{
  const char *p = s;
  while (n-- && *p)
    p++;
  return p - s;
}

static inline void printnum(void (*putch)(int, void**), void **putdat,
                    unsigned long long num, unsigned base, int width, int padc)
{
  unsigned digs[sizeof(num)*CHAR_BIT];
  int pos = 0;

  while (1)
  {
    digs[pos++] = num % base;
    if (num < base)
      break;
    num /= base;
  }

  while (width-- > pos)
    putch(padc, putdat);

  while (pos-- > 0)
    putch(digs[pos] + (digs[pos] >= 10 ? 'a' - 10 : '0'), putdat);
}

static unsigned long long getuint(va_list *ap, int lflag)
{
  if (lflag >= 2)
    return va_arg(*ap, unsigned long long);
  else if (lflag)
    return va_arg(*ap, unsigned long);
  else
    return va_arg(*ap, unsigned int);
}

static long long getint(va_list *ap, int lflag)
{
  if (lflag >= 2)
    return va_arg(*ap, long long);
  else if (lflag)
    return va_arg(*ap, long);
  else
    return va_arg(*ap, int);
}

static double getfloat(va_list *ap)
{
    double num = va_arg(*ap, double);
    return num; 
}

static void vprintfmt(void (*putch)(int, void**), void **putdat, const char *fmt, va_list ap)
{
  register const char* p;
  const char* last_fmt;
  register int ch, err;
  unsigned long long num;
  double lf;
  unsigned long long intnum;
  int base, lflag, width, precision, altflag;
  char padc;

  while (1) {
    while ((ch = *(unsigned char *) fmt) != '%') {
      if (ch == '\0')
        return;
      fmt++;
      putch(ch, putdat);
    }
    fmt++;

    // Process a %-escape sequence
    last_fmt = fmt;
    padc = ' ';
    width = -1;
    precision = -1;
    lflag = 0;
    altflag = 0;
  reswitch:
    switch (ch = *(unsigned char *) fmt++) {

    // flag to pad on the right
    case '-':
      padc = '-';
      goto reswitch;
      
    // flag to pad with 0's instead of spaces
    case '0':
      padc = '0';
      goto reswitch;

    // width field
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      for (precision = 0; ; ++fmt) {
        precision = precision * 10 + ch - '0';
        ch = *fmt;
        if (ch < '0' || ch > '9')
          break;
      }
      goto process_precision;

    case '*':
      precision = va_arg(ap, int);
      goto process_precision;

    case '.':
      if (width < 0)
        width = 0;
      goto reswitch;

    case '#':
      altflag = 1;
      goto reswitch;

    process_precision:
      if (width < 0)
        width = precision, precision = -1;
      goto reswitch;

    // long flag (doubled for long long)
    case 'l':
      lflag++;
      goto reswitch;

    // character
    case 'c':
      putch(va_arg(ap, int), putdat);
      break;

    // string
    case 's':
      if ((p = va_arg(ap, char *)) == NULL)
        p = "(null)";
      if (width > 0 && padc != '-')
        for (width -= strnlen(p, precision); width > 0; width--)
          putch(padc, putdat);
      for (; (ch = *p) != '\0' && (precision < 0 || --precision >= 0); width--) {
        putch(ch, putdat);
        p++;
      }
      for (; width > 0; width--)
        putch(' ', putdat);
      break;

    // (signed) decimal
    case 'd':
      num = getint(&ap, lflag);
      if ((long long) num < 0) {
        putch('-', putdat);
        num = -(long long) num;
      }
      base = 10;
      goto signed_number;

    // (signed) rounded float number
    case 'f':
	  lf = getfloat(&ap);
      intnum = (long long) lf;
      num  = (long long) (10000*lf);
      if (intnum < 0) {
        putch('-', putdat);
        intnum = -intnum;
      }
      base = 10;
      printnum(putch, putdat, intnum, base, width, padc); 
      putch('.', putdat);
      num -= (10000*intnum);
      printnum(putch, putdat, num, base, width, padc); 
      break;

    // unsigned decimal
    case 'u':
      base = 10;
      goto unsigned_number;

    // (unsigned) octal
    case 'o':
      // should do something with padding so it's always 3 octits
      base = 8;
      goto unsigned_number;

    // pointer
    case 'p':
      static_assert(sizeof(long) == sizeof(void*));
      lflag = 1;
      putch('0', putdat);
      putch('x', putdat);
      /* fall through to 'x' */

    // (unsigned) hexadecimal
    case 'x':
    case 'X':
      base = 16;
    unsigned_number:
      num = getuint(&ap, lflag);
    signed_number:
      printnum(putch, putdat, num, base, width, padc);
      break;

    // escaped '%' character
    case '%':
      putch(ch, putdat);
      break;
      
    // unrecognized escape sequence - just print it literally
    default:
      putch('%', putdat);
      fmt = last_fmt;
      break;
    }
  }
}

int printf(const char* fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);

  vprintfmt((void*)putchar, 0, fmt, ap);

  va_end(ap);
  return 0; 
}

