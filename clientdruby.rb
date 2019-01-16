require 'drb/drb'
DRb.start_service
puts 'welcome'
cerrar = false
while !cerrar do
    puts 'introduzca el nombre del archivo junto con su direccion'
    nombre = gets.chomp
    begin
        
    
    remote_object = DRbObject.new_with_uri('druby://localhost:9999')
    file = nombre
    nombre = nombre.split('/')
    nombre = nombre.last
    archivo = IO.read(file)
    remote_object.greet(archivo,nombre)   #=> 'Hello, world!'
    puts 'Deseas salvar otro archivo? S o N'
    respuesta = gets.chomp
    correcto = false
    while !correcto
        if respuesta == 'S'
            cerrar = true
            correcto = true
        elsif respuesta == 'N'
            cerrar = false
            correcto = true
        else 
            puts 'ha introducido un valor incorrecto'
        end     
    end
    rescue DRb::DRbConnError => e
    puts "excepcion es estaaaa   #{e}"    
    end
    
end 
