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
require 'timeout'

class Server

  MULTICAST_ADDR = "224.0.0.1"
  BIND_ADDR = "0.0.0.0"
  PORT = 3000

  def initialize ()
    @rank = nil
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
    initserver(socket)

    listen (socket)
    #constMsg("askrank")
    #publishRank
    if @rank == 1
      actualizar()
    end
    puts "Servidor Inciado..."
    @response.join


  end

  def actualizar()
    puts "actualizar"
    @act = Thread.new do
      loop {
        sleep(10)
        hash = {:destino => MULTICAST_ADDR, :content => @connections[:servers].to_json, :type => "actualizar"}.to_json
        send(hash.to_s)
    }
    end
    puts "hilo actualizar cerrado"
  end

  def listen (socket)
    @response = Thread.new do
      loop {
            message, sender = socket.recvfrom(255)
            remote_host = sender[3]
            #puts "mensaje recibido: #{message}, sender is #{sender}"
            data = JSON.parse(message)
            if (data["destino"]==MULTICAST_ADDR)
              if data["content"] == "mi rank"
                # envio mi rank al nuevo server  BUSCAR SI SE PUEDE MANDAR UN MENSAJE UNICAST
                sendRank(remote_host)
                puts @connections
              elsif data["content"] == "askrank" and @rank == 1
                  puts "sending rank"
                  rankmax = findrankmax
                  constMsg("turank",rankmax+1)
                  @connections[:servers][remote_host] = rankmax+1
                  puts @connections
                  puts "in json #{@connections[:servers].to_json}"
              elsif data["type"] == "actualizar"
                @connections[:servers] = JSON.parse(data["content"])
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

  def constMsg(msg,rank)
    text = '{"destino" : "'+MULTICAST_ADDR+'" , "content" : "'+msg+'","rank":'+rank.to_s+'}'
    send(text)
  end

  def selectRank
    for cont in (0..10)
      text = '{"rank":'+cont+',"destino":"192.168.1.7","content":"solicitud rank"'
    end
  end


  def initserver(socket)
    constMsg("askrank","0")
    begin
      timeout(1) do
          msgcorrect = false
          while !msgcorrect
            message,sender = socket.recvfrom(255)
            data = JSON.parse(message)
            puts data
            if data["content"] == "turank"
              msgcorrect = true
              @rank = Integer(data.fetch("rank"))
              puts "ranking reibido: #{@rank}"
            end
          end
      end
    rescue Timeout::Error
      puts "Tiempo expirado, autoasignando ranking..."
      @rank = 1
      ip = getIp
      @connections[:servers][ip] = @rank
      puts @connections
    end
  end


  def findrankmax
    max = 0
    @connections[:servers].each do |ip,rank|
      puts "rank is #{rank}"
      if max < rank
        max = rank
      end
    end
    return max
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
#puts "Ingrese rank del server: "
#rank = $stdin.gets.chomp
Server.new()
