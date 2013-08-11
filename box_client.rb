#!/usr/bin/ruby
require 'socket'
# establish ongoing connection
id=ARGV.first.to_i
port=3000 + id
clientSession = TCPSocket.new( "localhost", port )
puts "log: starting connection at port: " + port.to_s
#wait for messages from the server
while !(clientSession.closed?) &&
    (serverMessage = clientSession.gets)
  ## lets output our server messages
  puts serverMessage
  clientSession.puts "Message accepted\n"
  #if one of the messages contains 'Goodbye' we'll disconnect
  ## we disconnect by 'closing' the session.
  if serverMessage.include?("Goodbye")
    puts "log: closing connection"
    clientSession.close
  end
end #end loop
