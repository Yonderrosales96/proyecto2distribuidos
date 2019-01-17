require 'drb/drb'
puts 'welcome'
cerrar = false
while !cerrar do
    puts 'COMMIT -path  --> para guardar archivo'
    msg = $stdin.gets.chomp
    msg = msg.split(" -")
    case msg[0].upcase
      when  "COMMIT"
        begin
          nombre = msg[1]
          remote_object = DRbObject.new_with_uri('druby://localhost:9999')
          file = nombre
          nombre = nombre.split('/')
          nombre = nombre.last
          puts "leyendo"
          size = File.size file
          archivo = IO.read(file)
          puts "escribiendo"
          remote_object.greet(archivo,nombre,size)   #=> 'Hello, world!'
          puts 'Deseas salvar otro archivo? S o N'
          respuesta = gets.chomp
          correcto = false
          while !correcto
              if respuesta == 'S'
                  cerrar = false
                  correcto = true
              elsif respuesta == 'N'
                  cerrar = true
                  correcto = true
              else
                  puts 'ha introducido un valor incorrecto'
                  puts 'Introduzca S o N'
                  respuesta = gets.chomp
              end
          end
        rescue DRb::DRbConnError => e
          puts "En estos momentos el servidor no esta en funcionamiento, intente de nuevo mas tarde"
        end
  end
end
