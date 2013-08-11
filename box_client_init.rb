#!/usr/bin/ruby
require 'socket'
# establish connection
clientSession = TCPSocket.new( "localhost", 2008 )
id=ARGV.first.to_i
port=3000 + id
idTrans=0
puts "log: starting init connection"
#send a quick message with id
clientSession.puts "Box: Calling with id:\n"
while (idTrans != port)
  clientSession.puts id.to_s + "\n"
  idTrans=clientSession.gets.to_i
  puts "log: Server waits at " + idTrans.to_s
end
puts "log: closing init connection"
clientSession.close
