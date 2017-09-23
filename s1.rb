# encoding: UTF-8
require 'thread'
require 'socket'

class Server
  def initialize(ip, port)
    @server = TCPServer.open(ip, port)
    @connections = {}
    @clients = {}
    @spacer = 0.chr
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        message = client.gets.chomp
        status = message.split(@spacer).first
        message = message.split(@spacer).first
        case status
          when 'R'
            @connections.each do |other_client, other_nickname|
              if message == other_nickname
                client.puts 'This username already exist'
                Thread.kill self
              end
            end
            puts "New user: #{message}"
            @connections[client] = message
            client.puts 'Connection established'
          when 'M'
            @connections.each_key do |other_client|
                client.puts message
            end
        end
      end
    }.hoin
  end
end

server = Server.new('localhost', 60231)
