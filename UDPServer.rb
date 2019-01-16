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
require 'drb/drb'

class Server

  MULTICAST_ADDR = "224.0.0.1"
  BIND_ADDR = "0.0.0.0"
  PORT = 3000

  def initialize ()
    @rank = nil
    @ip = getIp
    @rankPrincipal = 1
    @connections = Hash.new
    @connections[:servers] = Hash.new
    @connections[:status] = Hash.new
    @connections[:timeUltimoPing] = Hash.new
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

    # if @rank == 1
    if @rank == @rankPrincipal
      actualizar()
      verificarStatusServers()
      putOnLine()
    else
      putOnLine()
      verificarStatusPrincipal()
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
        # hash = {:destino => MULTICAST_ADDR, :content => @connections[:status].to_json, :type => "actualizar status"}.to_json
        # send(hash.to_s)
        # hash = {:destino => MULTICAST_ADDR, :content => @connections[:timeUltimoPing].to_json, :type => "actualizar timeUltimoPing"}.to_json
        # send(hash.to_s)
      }
    end
    puts "hilo actualizar cerrado"
  end

  def putOnLine ()
    @onLine = Thread.new do
      loop{
        hash = {:rank =>@rank ,:destino => MULTICAST_ADDR, :content => "OnLine", :type => "ping"}.to_json
        send(hash.to_s)
        sleep(10)
      }
    end
  end

  def verificarStatusServers ()
    @status = Thread.new do
      loop {
        sleep(10)
        @connections[:timeUltimoPing].each do |rank,time|
          if (Time.now - time) > 15
            @connections[:status][rank]="OffLine"
          end
        end
      }
    end
  end

  def sendNuevoCordinador ()
    hash = {:rank =>@rank ,:destino => MULTICAST_ADDR, :content => "Nuevo Cordinador", :type => "cordinador"}.to_json
    send(hash.to_s)
  end

  def verificarStatusPrincipal ()
    @status = Thread.new do
      loop {
        sleep(10)
        time = @connections[:timeUltimoPing][@rankPrincipal]
        if (Time.now - time) > 15
          puts "iniciando eleccion de cordinador"
          servers = @connections[:status].keys.sort
          servers.each do |rank|
            if @connections[:status][rank] == "OnLine" and rank != @rankPrincipal
              if rank == @rank
                @connections[:status][@rankPrincipal] = "OffLine"
                sendNuevoCordinador()
                actualizar()
                verificarStatusServers()
              end
              break
            end
          end
        end
      }
    end
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
              # elsif data["content"] == "askrank" and @rank == 1
              elsif data["content"] == "askrank" and @rank == @rankPrincipal
                  puts "sending rank"
                  rankmax = findrankmax
                  constMsg("turank",rankmax+1)
                  @connections[:servers][rankmax+1] = remote_host
                  #@connections[:servers][remote_host] = rankmax+1
                  puts @connections
                  puts "in json #{@connections[:servers].to_json}"
              elsif data["content"] == "rankPrincipal?" and @rank == @rankPrincipal
                  constMsg("rankPrincipal",@rankPrincipal)
              elsif data["type"] == "actualizar"
                @connections[:servers] = JSON.parse(data["content"])
              # elsif data["type"] == "actualizar status"
              #   @connections[:status] = JSON.parse(data["content"])
              # elsif data["type"] == "actualizar timeUltimoPing"
              #   @connections[:timeUltimoPing] = JSON.parse(data["content"])
                puts @connections
              elsif data["type"] == "ping"
                @connections[:status][data["rank"]]=data["content"]
                @connections[:timeUltimoPing][data["rank"]] = Time.now
              elsif data["type"] == "cordinador"
                @connections[:status][@rankPrincipal] = "OffLine"
                @rankPrincipal = data["rank"]
                puts("nuevo coordinador | rank : #{@rankPrincipal}")
              end
            elsif data["destino"] == @ip
              if data["content"] == "mi rank"
                @connections[:servers][data["rank"]] = remote_host
                # @connections[:servers][remote_host] = data["rank"]
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




  def initsecondserver
    object = MyApp.new
    Thread.new do
      DRb.start_service('druby://localhost:9999', object)
      DRb.thread.join
      puts 'aja'
    end
    puts 'finish'

  end

  def initserver(socket)
    constMsg("askrank","0")
    constMsg("rankPrincipal?","0")
    begin
      timeout(1) do
          msgcorrect = false
          while !msgcorrect
            message,sender = socket.recvfrom(255)
            data = JSON.parse(message)
            puts data
            if data["content"] == "turank"
              # msgcorrect = true
              @rank = Integer(data.fetch("rank"))
              puts "ranking reibido: #{@rank}"
            elsif data["content"] == "rankPrincipal"
              msgcorrect = true
              @rankPrincipal = Integer(data.fetch("rank"))
              puts "rank principal reibido: #{@rankPrincipal}"
            end
          end
      end
    rescue Timeout::Error
      puts "Tiempo expirado, autoasignando ranking..."
      @rank = 1
      @rankPrincipal = 1
      initsecondserver
      ip = getIp
      @connections[:servers][@rank] = ip
      puts @connections
    end
  end


  def findrankmax
    max = 0
    # @connections[:servers].each do |ip,rank|
    @connections[:servers].each do |rank,ip|
      puts "rank is #{rank}"
      if max < rank.to_i
        max = rank.to_i
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

class MyApp
  def greet(archivo,nombre)
    ruta = Dir.getwd
    arch = File.open("#{ruta}/archivos/#{nombre}","w")
    # arch = File.open("/home/yonder/Code/proyecto2distribuidos/archivos/#{nombre}",'w')
    IO.write(arch,archivo)
  end
end


Server.new()
