#!/usr/bin/ruby
require 'socket'

# ------------------------------------------------------------
# Input parameters
# ------------------------------------------------------------
if ARGV.length < 1
  $stderr.puts "Usage: #{$0} ID [port [Host [initPort]]]]"
    exit 1
end
#ID of box. 
id=ARGV.shift.to_s
#Port to connect to box
if ARGV.length>=1
  port=ARGV.shift.to_i
else
  port=0
end
#Host
if ARGV.length>=1
  host=ARGV.shift.to_s
else
  host='localhost'
end
#Port to connect to server initially
if ARGV.length>=1
  initPort=ARGV.shift.to_i
else
  initPort=2008
end

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

# Function to create initial connection
def initConnect(host, initPort, id)
  # Connect
  clientSession = TCPSocket.new( host, initPort )
  puts "log: starting init connection"
  #send a quick message with id
  clientSession.puts "Calling with id:\n"
  clientSession.puts id.to_s + "\n"

  while !(clientSession.closed?) &&
    (serverMessage = clientSession.gets)
    # lets output our server messages
    puts serverMessage
    if serverMessage.include?("port")
      port=clientSession.gets
      puts "log: Server waits at port: " + port
      puts "log: closing init connection"
      clientSession.close
    end
  end
  return port.to_i
end

# Function to acquire information about interfaces
def ifInfo
  # Run ifconfig. Return result in s
  s=IO.popen('ifconfig').read
  #p s
  # Find occurences of interface name, HWaddr, IPaddr and Mask
  # Result is returned in an array with each match as an element
  a=s.scan(/^\w+|HWaddr \S+|inet addr:\S+|Mask:\S+/)
  #p a
  # Go through array. Skip local interface. return string
  ok=true
  out=""
  interface=""
  a.each { |ss|
    # Substitute names, so all elements will end up being on the form <if>-<key>-<value> 
    ss=ss.gsub('HWaddr ', 'MACaddr-')
    ss=ss.gsub('inet addr:', 'IPaddr-')
    ss=ss.gsub('Mask:', 'Mask-')
    #Find interfaces. Drop local
    if ss=~/^\w+$/
      if ss=='lo'
        ok=false
        interface=ss
      else
        ok=true
        interface=ss
      end
    elsif ok 
      # Convert mask from being 255.255.255.0 form to 24 
      if ss=~/^Mask-(\S+)/
        mask=0
        sm=ss.scan(/\d+/)
        sm.each { |n|
          nn=n.to_i
          if nn==255
            mask=mask+8
          elsif nn==254
            mask=mask+7
          elsif nn==252
            mask=mask+6
          elsif nn==248
            mask=mask+5
          elsif nn==240
            mask=mask+4
          elsif nn==224
            mask=mask+3
          elsif nn==192
            mask=mask+2
          elsif nn==128
            mask=mask+1
          end
        }
        ss='Mask-'+mask.to_s
      end   
      out=out+interface+"-"+ss+"|"
    end
  }
  # remove last |
  out=out.chop
  #p out
  return out
end

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------
# Get port from initConnection, unless already there
if port==0
  port = initConnect(host, initPort, id)
end
clientSession = TCPSocket.new(host, port )
puts "log: starting connection at port: " + port.to_s
#wait for messages from the server
while !(clientSession.closed?) &&
    (serverMessage = clientSession.gets)
  ## lets output our server messages
  puts serverMessage
  # clientSession.puts "Message accepted\n"
  #if one of the messages contains 'Goodbye' we'll disconnect
  ## we disconnect by 'closing' the session.
  if serverMessage.include?("Goodbye\n")
    clientSession.puts "Closing connection"
    puts "log: closing connection"
    clientSession.close
  elsif serverMessage.include?("ifInfo")
    clientSession.puts ifInfo+"\n"
  else
    clientSession.puts "Unknown message\n"
  end

end #end loop
