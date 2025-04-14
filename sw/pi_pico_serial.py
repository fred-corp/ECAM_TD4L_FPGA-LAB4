#!/usr/bin/env python3
import serial
import struct

class PicoIce:
    def __init__(self, portName="/dev/tty.usbmodem103"):
        self.ser = serial.Serial(portName, 230400, timeout=0.5)

    def write(self, addr, data):
        to_send = struct.pack(">BBH", 0xAA, addr, data)
        self.ser.write(to_send)
        print(f"write send {to_send}")
        res = self.ser.read(2)
        print(f"write recv {res}")
        assert int(res[0]) == 0xAA, 'Invalid Write header'
        assert int(res[1]) == 0x0, 'Not successful response'
        assert len(res) == 2, 'Invalid response length'
        return res

    def read(self, addr):
        print("Read :")
        to_send = struct.pack(">BB", 0x55, addr)
        self.ser.write(to_send)
        print(f"read send {hex(to_send[0])}")
        print(f"read send {hex(to_send[1])}")
        res = self.ser.read(3)
        print(f"read recv {res}")
        assert int(res[0]) == 0x55, 'Invalid read header'
        assert len(res) == 3, 'Invalid response length : {}, expected 3'.format(str(len(res)))
        print(hex(res[0]))
        print(hex(res[1]))
        print(hex(res[2]))
        return struct.unpack(">H", res[1:])[0]

    def __del__(self):
        self.ser.close()

if __name__ == "__main__":
    ice = PicoIce()
    print(hex(ice.read(0x2)))
    ice.write(0x0, 0)
    ice.write(0x2, 1)
    ice.write(0x4, 0)
    ice.write(0x6, 0b0000000000111111)
