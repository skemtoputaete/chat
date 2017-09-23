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
        puts "#{Time.now} Connection accepted."
        loop {
          puts "New iteration"
          pair = client.gets.chomp
          pair = pair.split(@spacer)
          status = pair[0]
          message = pair[1]
          case status
            when 'R'
              puts "#{Time.now} Start register #{message}"
              @connections.each do |other_client, other_nickname|
                if message.to_sym == other_nickname
                  client.puts 'This username already exist'
                  Thread.kill self
                end
              end
              puts "#{Time.now} New user: #{message}"
              @connections[message.to_sym] = client
              client.puts 'Connection established'
            when 'M'
              b = 'M' + @spacer + message
              @connections.each_value do |other_client|
                puts other_client
                other_client.puts b
              end
              puts "#{Time.now} New message"
            else
              puts "#{Time.now} Unrecognized status."
          end
        }
      end
    }.join
  end
end

server = Server.new('localhost', 60231)
