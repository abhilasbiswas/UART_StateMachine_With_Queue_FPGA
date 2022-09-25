import serial
from time import sleep

ser = serial.Serial ("COM5", 8000000)                  #Read ten characters from serial port to data
msg = "Hello World\n"

#Send data to FPGA as Byte packets
ser.write(bytearray(bytearray(msg.encode())))
#Receive data from FPGA till \n
m = ser.readline()
print (m.decode())
ser.close()    