#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'socket'

# ------------------------------------------------------------
# Input parameters
# ------------------------------------------------------------
#Port to connect to server initially
if ARGV.length>=1
  initPort=ARGV.shift.to_i
else
  initPort=2008
end
#Base portnumber for Box connections
if ARGV.length>=1
  boxPortBase=ARGV.shift.to_i
else
  boxPortBase=3000
end
#Base portnumber for Rails connections
if ARGV.length>=1
  railsPortBase=ARGV.shift.to_i
else
  railsPortBase=4000
end

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------
puts "Starting up server..."

# abort on exceptions, otherwise threads will be silently killed in case
# of unhandled exceptions
Thread.abort_on_exception = true

# establish the server that handles incoming requests
server =
begin
  TCPServer.new( initPort )
rescue SystemCallError => ex
  raise "cannot initialize tcp server for port #{@port}: #{ex}"
end

# setup to listen and accept connections
while (initSession = server.accept)
  #start new thread conversation
  puts "log: Box initiated contact"
  ## Here we will establish a new thread for a connection client
  Thread.start do
    ## To be sure to output something on the server side
    ## to show that there has been a connection
    puts "log: Box connection from #{initSession.peeraddr[2]} at
          #{initSession.peeraddr[3]}"
    
    # Output message from box
    puts initSession.gets
    # Get ID
    id  = initSession.gets
    puts "log: Box ID is: " + id

    # A welcome message
    initSession.puts 'Welcome Box '+id.to_s

    # Simple calculation of ports. This should be made more intelligent later on
    boxPort=boxPortBase+id.to_i
    railsPort=railsPortBase+id.to_i
    puts "log: Port to box is: " + boxPort.to_s + ", Port to rails is: " + railsPort.to_s
    initSession.puts 'Waiting at port:'
    initSession.puts boxPort.to_s
    initSession.close

    # Creating Servers listening for box and Rails
    puts "log: Starting box interface server"
    boxServer =
      begin
        TCPServer.new( boxPort )
      rescue SystemCallError => ex
        raise "cannot initialize tcp server for port #{@port}: #{ex}"
      end
    puts "log: Starting rails interface server"
    railsServer =
      begin
        TCPServer.new( railsPort )
      rescue SystemCallError => ex
        raise "cannot initialize tcp server for port #{@port}: #{ex}"
      end

    
    railsSession = nil
    boxSession = nil
    sessions = []
    
    # Array containing Server threads
    serverThreads=[]
    serverThreads << Thread.start do
      loop do
        puts "log: waiting for rails to connect\n"
        railsSession = railsServer.accept
        puts "log: rails connected\n"
        sessions << railsSession
        # check every 0.5 second whether session has been closed
        while !(railsSession.eof) 
          sleep 0.5
        end
        puts "log: rails disconnected\n"
        sessions.delete( railsSession )
      end
    end
    serverThreads << Thread.start do
      loop do
        puts "log: waiting for box to connect\n"
        boxSession = boxServer.accept      
        puts "log: box connected\n"
        sessions << boxSession
        # check every 0.5 second whether session has been closed
        while !(boxSession.eof)
          sleep 0.5
        end
        puts "log: box disconnected\n"
        sessions.delete( boxSession )
      end
    end

    # Loop waiting for connection from either side
    loop do
      #sleep 0.01
      sleep 1
      if sessions.length == 0
        # Here we should do something smart.
      elsif sessions.length == 1
        # Here we should do something smart.
      else
        # puts "log: Waiting for messages to arrive\n"
        ready = select(sessions, nil, sessions)
        # Håndtering af errors
        ready[2].each do |c|
          c.close
          sessions.delete( c )
        end
        # Transfer messages
        ready[0].each do |c|
          if !(c.eof)
            if c == railsSession 
              data = c.gets
              puts "log: Attempting to transfer rails message: " + data
              if !boxSession.closed?
                boxSession.puts data
                puts "log: Rails message transferred"
              end
            end
            if c == boxSession
              data = boxSession.gets
              puts "log: Attempting to transfer box message: " + data
              if !railsSession.closed?
                railsSession.puts data
                puts "log: Box message transferred"
              end
            end
          end
        end
      end
    end    
  end #end thread
end #end loop
