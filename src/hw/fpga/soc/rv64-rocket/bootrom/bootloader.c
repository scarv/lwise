/* UART */
#define UART_BASE	  0x70600000
#define UART_RX         	0x00
#define UART_TX         	0x04
#define UART_STAT       	0x08
#define UART_CTRL       	0x0C

/* GPIO */
#define GPIO_BASE  	  0x70000000
#define GPIO_DATA           0x00
#define GPIO_CTRL           0x04

/* BRAM */
#define BRAM_BASE  	  0x80000000

static volatile int unsigned * uart_rx  = (volatile int unsigned*)(UART_BASE+UART_RX);
static volatile int unsigned * uart_tx  = (volatile int unsigned*)(UART_BASE+UART_TX);
static volatile int unsigned * uart_stat= (volatile int unsigned*)(UART_BASE+UART_STAT);
static volatile int unsigned * uart_ctrl= (volatile int unsigned*)(UART_BASE+UART_CTRL);

static volatile int unsigned * gpio_data= (volatile int unsigned*)(GPIO_BASE+GPIO_DATA);
static volatile int unsigned * gpio_ctrl= (volatile int unsigned*)(GPIO_BASE+GPIO_CTRL);

volatile unsigned int *uart_base_ptr = (volatile unsigned int *)(UART_BASE+0x1000u);

// bootloader command via UART
#define CMD_LOAD		0x1
#define CMD_RUN 		0x2
#define CMD_READ 		0x3
#define REP_DONE		0x4

static char hexchar[16]= "0123456789ABCDEF";

//! program vector in bram;
static volatile unsigned long int * pro_vec = (volatile unsigned long int *)(BRAM_BASE);
void (*startpro)(int argc, char* argv[]) = (void *)(BRAM_BASE);

//! Function used to recieve bytes from the host.
unsigned int recv_byte_from_host() {
	unsigned int valid = *uart_stat & (0x1);
    while(valid == 0) {valid = *uart_stat & (0x1);}// Wait until the RX FIFO receives a byte

    unsigned char tr = *uart_rx & 0xFF;
    return tr;
}
 
//! Function used to send bytes to the host.
void send_byte_to_host(unsigned char to_send) {
    unsigned int full = *uart_stat & (0x1<<3);
    while(full) {full = *uart_stat & (0x1<<3);}		// Wait until the TX FIFO is not full

    // Write the byte to the TX FIFO of the UART.
    unsigned int to_write = 0 | (unsigned int) to_send;
    *uart_tx = to_write;
}

void putlonghex(unsigned long int tp){
	for(int i=0;i<16;i++){
		unsigned char c = hexchar[((tp & 0xF000000000000000)>>60)];
		send_byte_to_host(c);
		tp <<=4;		
	}
}

void txstr(char *st, unsigned int len){
	unsigned int j;
	for(j=0;j<len;j++) send_byte_to_host(st[j]);
}

unsigned int uart_read_int() {
	unsigned int tr = 0;
	unsigned int b0, b1, b2, b3; 
	
	b0 = recv_byte_from_host();
	b1 = recv_byte_from_host();
	b2 = recv_byte_from_host();
	b3 = recv_byte_from_host();

	tr = (b0 << 0 ) |
	     (b1 << 8 ) |
		 (b2 << 16) |
		 (b3 << 24) ;

	return tr;
}

unsigned long int uart_read_long_int() {
	unsigned long int tr = 0;
	unsigned long int b0, b1, b2, b3, b4, b5, b6, b7; 
	
	b0 = recv_byte_from_host();
	b1 = recv_byte_from_host();
	b2 = recv_byte_from_host();
	b3 = recv_byte_from_host();
	b4 = recv_byte_from_host();
	b5 = recv_byte_from_host();
	b6 = recv_byte_from_host();
	b7 = recv_byte_from_host();

	tr = (b0 << 0 ) |
	     (b1 << 8 ) |
		 (b2 << 16) |
		 (b3 << 24) |
		 (b4 << 32) |
		 (b5 << 40) |
		 (b6 << 48) |
		 (b7 << 56) ;

	return tr;
}


//! Recieve data from the UART which we will load into memory.
void cmd_load_binary(){
	unsigned      int recv_size,  i;
    unsigned long int recv_data;

	recv_size = uart_read_int();

	for(i = 0; i < (recv_size/8); i ++) {
        recv_data  = uart_read_long_int();
		pro_vec[i] = recv_data;
	}
}

//! Recieve data from the UART which we will load into memory.
void cmd_read_mem(){
	unsigned      int read_size,  i;
    unsigned long int read_data;

	read_size = uart_read_int();

	for(i = 0; i < (read_size/8); i ++) {
        read_data  = pro_vec[i];
        txstr("\n 0x",4); 
        putlonghex(read_data);
	}

}

void bootloader()
{
	int i;
    int  argc = 0;
    char ** argv;
    unsigned int  cmd;
    unsigned char rep;



	*uart_ctrl = 0x3; // Enable the UART module. Disable interrupts and reset both FIFOs.
    *gpio_ctrl = 0x0;
    *gpio_data = 0x0;

	// Initialise the bram and the recieve data
    for(i = 0; i < 1024; i++){
    	pro_vec[i] = 0;
    }

	txstr("Bootloader\n",11);
    
	while(1) {

		cmd = recv_byte_from_host();

		switch(cmd) {
			case(CMD_LOAD):
			    cmd_load_binary();
				break;

			case(CMD_READ):
			    cmd_read_mem();
				break;

            case(CMD_RUN):
				startpro(argc, argv);

                for(i = 0; i < 2048; i++){  // for a neccessary delay
    	        pro_vec[i] = 0;
                }
                rep = REP_DONE;
                send_byte_to_host(rep);
                for(i = 0; i < 2048; i++){  // for a neccessary delay
    	        pro_vec[i] = 0;
                }
                *gpio_data = 3; // reset 
				break;
			default:
				break;

		}
    }

}


