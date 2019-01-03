require "socket"
class Client
  def initialize( server )
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"
      }
    end
  end

  def send
    puts "Ingrese nombre de usuario:"
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        @server.puts msg
        msg = msg.split(" ")
        case msg[0].upcase    
            when  'SENDFILE'
                begin
                    archivo = msg[1]
                    puts archivo
                    openfile = File.file? archivo
                    if openfile
                        size = File.size archivo
                        puts "tamano = #{size}"
                        @server.puts size
                        enviararchivo(archivo)
                    else
                        puts "El archivo no existe"        
                    end
                rescue Exception => e
                    puts e.message
                end    
        end
        #@server.puts( msg )
      }
    end
  end

  def enviararchivo(archivo)
    begin
        lineas = IO.readlines(archivo)
        lineas.each do |line|
           #puts "escribiendo"
            @server.write(line)
        end
        @server.write("end")    
    rescue Exception => e
        puts e.message
    end    
  end
end



puts "Ingrese la direccion ip del servidor"
ip = $stdin.gets.chomp
server = TCPSocket.open( ip, 3000 )
Client.new( server )
