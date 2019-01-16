# server.rb
require 'drb/drb'

class MyApp
  def greet(archivo)
    arch = File.open("/home/yonder/Code/proyecto2distribuidos/archivos/newarch.png",'w')
    IO.write(arch,archivo)
  end
end

object = MyApp.new
begin
DRb.start_service('druby://localhost:9999', object)
rescue Exception => e
  puts e.message
end    
DRb.thread.join