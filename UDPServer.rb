# require 'socket'
#
# s = UDPSocket.new
# s.bind(nil, 1234)
# 5.times do
#   text, sender = s.recvfrom(16)
#   puts text
# end


# ---------------------  socket UDO  --------------------
# require 'socket'
# host = 'localhost'
# port = 1234
# s = UDPSocket.new
# s.bind(nil, port)
# s.send("1", 0, host, port)
# 5.times do
#   text, sender = s.recvfrom(16)
#   remote_host = sender[3]
#   puts "#{remote_host} sent #{text}"
#   response = (text.to_i * 2).to_s
#   puts "We will respond with #{response}"
#   s.send(response, 0, host, port)
#   sleep(2)
# end
#----------------------------------------------------------

#----------------Multicasting -----------------------------


require "socket"
require "ipaddr"
require "json"

class Server

  MULTICAST_ADDR = "224.0.0.1"
  BIND_ADDR = "0.0.0.0"
  PORT = 3000

  def initialize (rank)
    @rank = rank
    @ip = getIp
    @connections = Hash.new
    @connections[:servers] = Hash.new
    run
  end

  def getIp
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
    return ip.ip_address
  end

  def run
    socket = UDPSocket.new
    membership = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton

    socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, membership)
    socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)

    socket.bind(BIND_ADDR, PORT)
    puts "Servidor Inciado..."
    listen (socket)
    publishRank
    @response.join

  end

  def listen (socket)
    @response = Thread.new do
      loop {
        message, sender = socket.recvfrom(255)
        remote_host = sender[3]
        puts message
        data = JSON.parse(message)
        if (data["destino"]==MULTICAST_ADDR)
          if data["content"] == "mi rank"
            @connections[:servers][remote_host] = data["rank"]
            # envio mi rank al nuevo server  BUSCAR SI SE PUEDE MANDAR UN MENSAJE UNICAST
            sendRank(remote_host)
            puts @connections
          end
        elsif data["destino"] == @ip
          if data["content"] == "mi rank"
            @connections[:servers][remote_host] = data["rank"]
            puts @connections
          end
        end
        # puts "origen : -#{remote_host}- destino : -#{data["destino"]}- rank : -#{data["rank"]}- sent #{data["content"]}"
      }
    end
  end

  def send (msg)
    socket = UDPSocket.open
    socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 1)
    socket.send(msg, 0, MULTICAST_ADDR, PORT)
    socket.close
    # @request = Thread.new do
    #   loop {
    #     msg = $stdin.gets.chomp
    #     socket.send(msg, 0, MULTICAST_ADDR, PORT)
    #     #socket.send(ARGV[0], 0, MULTICAST_ADDR, PORT)
    #   }
    #   socket.close
    # end
  end

  def sendRank (addr)
    text = '{"rank" : '+@rank+' , "destino" : "'+addr+'" , "content" : "mi rank"}'
    send(text)
  end

  def publishRank
    text = '{"rank" : '+@rank+' , "destino" : "'+MULTICAST_ADDR+'" , "content" : "mi rank"}'
    send(text)
  end

  def selectRank
    for cont in (0..10)
      text = '{"rank":'+cont+',"destino":"192.168.1.7","content":"solicitud rank"'
    end
  end

end


# MULTICAST_ADDR = "224.0.0.1"
# BIND_ADDR = "0.0.0.0"
# PORT = 3000
#
# socket = UDPSocket.new
# membership = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton
#
# socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, membership)
# socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
#
# socket.bind(BIND_ADDR, PORT)
#
# hilo = Thread.new(){
# loop do
#   message, sender = socket.recvfrom(255)
#   remote_host = sender[3]
#   puts "#{remote_host} sent #{message}"
# end
# }

# puts "Servidor Inciado..."
# text = '{"rank":2,"destino":"192.168.1.7","content":"Hola como estas ?"}'
# data = JSON.parse(text)
# puts data["origen"]
#
# hilo.join
puts "Ingrese rank del server: "
rank = $stdin.gets.chomp
Server.new(rank)
