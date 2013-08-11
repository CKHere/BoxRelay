#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'socket'
# establish connection
## We need to tell the client where to connect
port=3000 + ARGV.shift.to_i
puts "log: connect on " + port.to_s
clientSession = TCPSocket.new( "localhost", port )
puts "log: starting connection"
message = ARGV.shift.to_s
puts "log: " + message
clientSession.puts message + "\n"
puts clientSession.gets
clientSession.close
puts "log: connection closed"
