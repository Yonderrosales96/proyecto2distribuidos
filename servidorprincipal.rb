require "socket"
class Server
  def initialize( port, ip )
    @server = TCPServer.open( ip, port )
    @connections = Hash.new
    @servidorR = Hash.new   ##Hash de los servidores de respaldo
    @connections[:servidorr] = @servidorR
    directorio = Dir.getwd
    Dir.mkdir("#{directorio}/archivos") unless Dir.exist?("#{directorio}/archivos")
    puts "Servidor Inicializado"
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do | servidorR |
        begin
            nick_name = servidorR.gets.chomp.to_sym
            @connections[:servidorr].each do |other_name, other_client|
              puts "other name : #{other_name} y other_client : #{other_client}"
              if nick_name == other_name || client == other_client
                client.puts "Nombre de usuario ya existe"
                Thread.kill self
              end
            end
            puts "#{nick_name} #{servidorR}"
            @connections[:servidorr][nick_name] = servidorR
            servidorR.puts "Se ha establecido la coneccion, Bienvenido"
            listen_user_messages( nick_name, servidorR )
        rescue Exception => e
            puts e.message
        end    
      end
    }.join
  end

  def listen_user_messages( username, client )
    loop {
      begin
        msg = client.gets.chomp
        msg = msg.split(" ")
        accion(msg,client)
      rescue Exception => e
        puts e.message
      end    
    }
  end

  def accion(msg,client)
    case msg[0]    
      when  'SENDFILE'
          begin
              archivo = msg[1]
              archivo = archivo.split("/")
              archivo = archivo.last  
              puts "accion sendfile #{archivo}"
              arch = File.open("/home/yonder/Code/proyecto2distribuidos/archivos/#{archivo}",'w') #Cambiar aqui la direccion
              puts "abierto"
              fin = false
              seek = 0
              size = Integer(client.gets)
              while !fin
                buffer = client.read(size)
              #  puts "despues"
                #iif buffer == "end"
                #  fin = true
                #  puts "fin"
               # else
                  seek = seek + IO.write(arch,buffer,seek)
                  puts "continue"
                  fin = true
                #end
              end  
          rescue Exception => e
              puts e.message
          end    
    end
  end

end
puts "Inicializando Servidor"
puts "Ingrese direccion IP"
ip = $stdin.gets.chomp
Server.new( 3000, ip )
#openfile = File.file? "/home/yonder/Code/proyecto2distribuidos/archivos/#{archivo}"