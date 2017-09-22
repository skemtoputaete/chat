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
            if message[1] == 'F'
              signup(true)
            else
              puts 'You have been successfully registered!'
            end
          when 'A'
            if message[1] == 'F'
              login(true)
            else
              puts 'You have been successfully authorized!'
            end
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
          text = $stdin.gets.chomp
          message += text
          @server.puts message.encode('UTF-8')
          puts @nickname + ' :' + text
        end
      end
    end

    def check_connection
      @server.puts 'C' + @spacer
    end

    def signup(result = nil)
      if result
        puts 'The nickname is used!'
      end
      puts 'Enter login and password through space.'
      login_password = gets
      message = 'R' + @spacer + login_password
      login = login.split.first
      @nickname = login
      @server.puts message.encode('UTF-8')
    end

    def login(result = nil)
      if result
        puts 'Wrong password!'
      end
      puts 'Enter login and password through space.'
      login_password = gets
      message = 'A' + @spacer + login_password
      login = login.split.first
      @nickname = login
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
