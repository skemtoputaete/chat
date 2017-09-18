# encoding: UTF-8
require 'socket'

class Client
  def initialize(server)
    @spacer = 0.chr
    @server = server
    @request = nil
    @response = nil
    listen
    check_connection
    action
    send
    @request.join
    @response.join
  end

  private
    def listen
      @response = Thread.new do
        loop do
          message = @server.gets.chomp
          message = message.split(@spacer)
          case message[0]
          when 'C'
            puts "Connection information: #{message[1]}"
          when 'R'
            puts "Registration information: #{message[1]}"
          when 'A'
            puts "Autorization information: #{message[1]}"
          when 'M'
            puts "#{message[1]}"
          when 'E'
            puts "#{message[1]}"
          end
        end
      end
    end

    def send
      @request = Thread.new do
        loop do
          message = 'M' + @spacer
          message += $stdin.gets.chomp
          puts message
          @server.puts message.encode('UTF-8')
        end
      end
    end

    def check_connection
      @server.puts 'C' + @spacer
    end

    def signup
      puts 'Enter login and password through space.'
      login_password = gets
      message = 'R' + @spacer + login_password
      @server.puts message.encode('UTF-8')
    end

    def login
      puts 'Enter login and password through space.'
      login_password = gets
      message = 'A' + @spacer + login_password
      @server.puts message.encode('UTF-8')
    end

    def action
      puts 'Choose action: '
      puts '1 - sign up'
      puts '2 - log in'
      choice = gets.chomp
      case choice
      when '1'
        signup
      when '2'
        login
      end
    end
end

server = TCPSocket.open('localhost', 60231)
Client.new(server)
