#!/usr/bin/python3

"""
A python3 script for downloading binaries to a soft RISC-V core running on a FPGA board.
"""

import sys
import argparse
import logging as log
import time
import serial

CMD_LOAD = bytes([0x1])
CMD_RUN  = bytes([0x2])
CMD_READ = bytes([0x3])
REP_DONE = bytes([0x4])

def parse_args():
    """
    Responsible for parsing all arguments to the flow script.
    """
    parser = argparse.ArgumentParser()

    parser.add_argument("--port", type=str, default="/dev/ttyUSB2",
        help="Which serial port used to communicate with the target.")
    
    parser.add_argument("--baud", type=int, default=115200,
        help="Baud rate to communicate with the target at.")

    parser.add_argument("--timeout", type=int, default=3,
        help="Timeout after this many seconds trying to communicate.")
    
    subs = parser.add_subparsers(help="What do do.", dest="cmd")

    p_upload = subs.add_parser("upload",help="Upload a new program for the RISC-V core.")
    p_upload.add_argument("file", type=argparse.FileType("rb"),
        help="The file to send to the target")
    p_upload.add_argument("--stdout", action="store_true", 
        help="After uploading, leave the port open and print whatever we recieve")

    p_stdout = subs.add_parser("stdout",
        help="Continually print STDOUT from the RISC-V core to the terminal")
    p_stdout.add_argument("file", type=argparse.FileType("rb"),
        help="The file sent to the target")
    return parser.parse_args()


def upload(args,port):
    """
    Upload a new binary blob, which is hopefully a program, to the
    RISC-V shared memory.
    """
    data_tosend = args.file.read()
    data_length = len(data_tosend).to_bytes(4, byteorder='little')
    
    sent = 0
    print("-- Programming is sending %d bytes to %s" % (len(data_tosend),port.port))
    #print(data_length)
    sent += port.write(CMD_LOAD)
    time.sleep(0.1)
    sent += port.write(data_length)
    port.flush()
    hp = int(len(data_tosend)/2)

    sent += port.write(data_tosend[:hp])
    port.flush()
    time.sleep(0.1)
    sent += port.write(data_tosend[hp:])
    port.flush()
    #print("-- Sent %d bytes in total" % sent)
    time.sleep(2)
    sent += port.write(CMD_RUN)
    port.flush()

    if(args.stdout):
        read_stdout(args,port)
    else:
        port.close()
        sys.exit(0)


def read_stdout(args,port):
    """
    Read the standard output of the RISC-V core.
    """
    #print("-- Reading STDOUT from RISC-V core.")
    #print("-- CTRL-C to exit.")

    try:
        sys.stdout.write(">> ");
        while(True):
            rdata = port.read(1).decode("ascii")
            if  (rdata == REP_DONE.decode("ascii")):
                sys.stdout.write("\n")
                port.close()
                sys.exit(0)
            elif(rdata == "\n"):
                sys.stdout.write("\n>> ")
            else:
                sys.stdout.write(rdata)
            sys.stdout.flush()
    except KeyboardInterrupt:
        print()
        pass
    port.close()
    sys.exit(0)

def main():
    """
    Main function for the script
    """

    args    = parse_args()

    port    = serial.Serial()
    port.baudrate = args.baud
    port.port     = args.port
    port.timeout  = args.timeout

    port.open()

    if(port.is_open):
        log.info("Opened port %s at baud %d" % (port.port,port.baudrate))
    else:
        log.error("Failed to open port %s at baud %d" % (
            port.port,port.baudrate))
        sys.exit(1)

    if(args.cmd == "upload"):
        upload(args,port)

    elif(args.cmd == "stdout"):
        data_tosend = args.file.read()
        data_length = len(data_tosend).to_bytes(4, byteorder='little')
        port.write(CMD_READ)
        port.write(data_length)
        read_stdout(args,port)

    else:
        log.error("Unknown command: %s" % args.cmd)
        port.close(0)
        sys.exit(1)


if(__name__ == "__main__"):
    main()
