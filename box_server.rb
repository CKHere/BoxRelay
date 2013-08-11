#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'socket'
puts "Starting up server..."

# abort on exceptions, otherwise threads will be silently killed in case
# of unhandled exceptions
Thread.abort_on_exception = true

# establish the server that handles incoming requests
## Server established to listen for connections on port 2008
server =
begin
  TCPServer.new( 2008 )
rescue SystemCallError => ex
  raise "cannot initialize tcp server for port #{@port}: #{ex}"
end
# setup to listen and accept connections
while (initSession = server.accept)
  #start new thread conversation
  puts "log: Box initiated contact"
  ## Here we will establish a new thread for a connection client
  Thread.start do
    ## I want to be sure to output something on the server side
    ## to show that there has been a connection
    puts "log: Box connection from #{initSession.peeraddr[2]} at
          #{initSession.peeraddr[3]}"
    
    puts initSession.gets
    id  = initSession.gets
    puts "log: Box ID is: " + id
    
    boxPort=3000+id.to_i
    railsPort=3000+id.to_i+1
    puts "log: Port to box is: " + boxPort.to_s + ", Port to rails is: " + railsPort.to_s
    initSession.puts boxPort.to_s
    initSession.puts "Goodbye"
    initSession.close

    # Opstart af servere
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
    
    # Threads med servere
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

    # Loop, der læser og skriver
    loop do
      sleep 0.01
      # sleep 1
      if sessions.length == 0
        # puts "log: Waiting for connections\n"
      elsif sessions.length == 1
        # puts "log: Waiting for secondary connection\n"      
        # ready = select(sessions, nil, sessions)
        # # Håndtering af errors
        # ready[2].each do |c|
        #   c.close
        #   sessions.delete( c )
        # end
        # ready[0].each do |c|
        #   puts c.gets
        #   c.puts "No connection\n"
        # end
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
            if c == boxSession
              data = boxSession.gets
              puts "log: Attempting to transfer box message: " + data
              if !railsSession.closed?
                railsSession.puts data
                puts "log: Box message transferred"
              end
            end
            if c == railsSession 
              data = c.gets
              puts "log: Attempting to transfer rails message: " + data
              if !boxSession.closed?
                boxSession.puts data
                puts "log: Rails message transferred"
              end
            end
          end
        end
      end
    end    
  end #end thread
end #end loop
