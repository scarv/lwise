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

static volatile int unsigned * uart_rx  = (volatile int unsigned*)(UART_BASE+UART_RX);
static volatile int unsigned * uart_tx  = (volatile int unsigned*)(UART_BASE+UART_TX);
static volatile int unsigned * uart_stat= (volatile int unsigned*)(UART_BASE+UART_STAT);
static volatile int unsigned * uart_ctrl= (volatile int unsigned*)(UART_BASE+UART_CTRL);

volatile unsigned int *uart_base_ptr = (volatile unsigned int *)(UART_BASE+0x1000u);

// bootloader command via UART
#define CMD_UPLOAD		0x1
#define REP_DONE		0x4


//! program vector in bram;
volatile unsigned int * pro_vec = (volatile unsigned int *)(BRAM_BASE);
void (*startpro)(void) = (void *)(BRAM_BASE);

void uart_init() {
	*uart_ctrl = 0x3; // Enable the UART module. Disable interrupts and reset both FIFOs.
}

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
    unsigned int to_write = 0 | to_send;
    *uart_tx = to_write;
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

//! Recieve data from the UART which we will load into memory.
void cmd_load_binary(){
	unsigned int recv_size;

	recv_size = uart_read_int();

	for(int i = 0; i < (recv_size/4); i ++) {
		pro_vec[i] = uart_read_int();
	}

//	txstr("Download is completed. The program is running\n",47);
}

void bootloader()
{
	int i,j;
    
    uart_init();

	txstr("\n\n\nSCARV Project, Board Support Package.\n",41);

	// Initialise the bram and the recieve data
    for(int i = 0; i < 1024; i++){
    	pro_vec[i] = 0;
    }

	txstr("Bootloader:\n",11);
	txstr("\nWaiting to download a program ...\n\n\n",37);
    
	while(1) {

		unsigned int cmd = recv_byte_from_host();

		switch(cmd) {
			case(CMD_UPLOAD):
			    cmd_load_binary();
				for(volatile int j = 0; j < 1024; j++) ;
				startpro();

	            // Reset the bram and the recieve data
                for(int i = 0; i < 1024; i++){
    	        pro_vec[i] = 0;
                }
                unsigned char response = REP_DONE;
                send_byte_to_host(response);
				break;
			default:
				break;

		}
    }

}


