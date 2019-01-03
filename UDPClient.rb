# require 'socket'
#
# s = UDPSocket.new
#
# s.send("hello", 0, 'localhost', 1234)


#----------------Multicasting -----------------------------
require "socket"

MULTICAST_ADDR = "224.0.0.1"
PORT = 3000

socket = UDPSocket.open
socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 1)
text = '{"rank":2,"destino":"192.168.1.7","content":"Hola como estas ?"}'
socket.send(text, 0, MULTICAST_ADDR, PORT)
#socket.send(ARGV[0], 0, MULTICAST_ADDR, PORT)
socket.close
