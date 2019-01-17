require 'lsof_parser'

data = Lsof::Parser.new( :arguments => "9999 localhost" )