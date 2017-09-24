# encoding: UTF-8
require 'socket'

class Client
  def initialize(server)
    @server = server
    @spacer = 0.chr
    @request = nil
    @response = nil
    @registered = false
    @authorized = false
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
              @registered = true
              puts 'You have been successfully registered!'
            end
          when 'A'
            if message[1] == 'F'
              login(true)
            else
              @authorized = true
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
          if @registered || @authorized
            text = $stdin.gets.chomp
            if text == '!quit'
              message = 'E' + @spacer + @nickname
            else
              time = Time.now.strftime("%H:%M:%S")
              message = 'M' + @spacer + @nickname + " (#{time}): "
              message += text
            end
            @server.puts message.encode('UTF-8')
          end
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
      begin
        puts 'Enter login and password through space.'
        login_password = gets.chomp
        login_password = login_password.split
      end while login_password.size < 2
      login = login_password[0]
      password = login_password[1]
      password = password.crypt('$hf$qwe')
      message = 'R' + @spacer + "#{login} #{password}"
      @nickname = login
      @server.puts message.encode('UTF-8')
    end

    def login(result = nil)
      if result
        puts 'Wrong password!'
      end
      begin
        puts 'Enter login and password through space.'
        login_password = gets.chomp
        login_password = login_password.split
      end while login_password.size < 2
      login = login_password[0]
      password = login_password[1]
      password = password.crypt('$hf$qwe')
      message = 'A' + @spacer + "#{login} #{password}"
      @nickname = login
      @server.puts message.encode('UTF-8')
    end

    def action
      puts 'Choose action: '
      puts '1 - sign up'
      puts '2 - log in'
      begin
        choice = gets.chomp
        case choice
        when '1'
          signup
          right_command = true
        when '2'
          login
          right_command = true
        else
          right_command = false
        end
      end while !right_command
    end
end

server = TCPSocket.open('localhost', 60231)
Client.new(server)
