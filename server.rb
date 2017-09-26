# encoding: UTF-8
require 'thread'
require 'socket'

class Server
  def initialize(ip, port)
    @server = TCPServer.open(ip, port)
    @connections = {}
    @clients = {}
    @spacer = 0.chr
    get_clients_info
    run
  end

  def get_clients_info
    clients = File.readlines('clients.txt')
    clients.each do |client|
      login_password = client.split
      login = login_password[0].to_sym
      password = login_password[1]
      @clients[login] = password
    end
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} new connection accepted."
        loop {
          puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} waiting for new message..."
          status_message = client.gets.chomp
          puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} new message #{status_message}"
          status_message = status_message.split(@spacer)
          status = status_message[0]
          message = status_message[1]
          case status
            when 'C'
              response = 'C' + @spacer + 'connection is good.'
              client.puts response
            when 'E'
              client_left(message, client)
            when 'R'
              register(message, client)
            when 'A'
              authorize(message, client)
            when 'M'
              send_to_all(message, client)
            else
              puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} unrecognized status."
          end
        }
      end
    }.join
  end

  def register(message, client)
    login_password  = message.split
    nickname = login_password[0].to_sym
    @clients.each_key do |other_nickname|
      if nickname == other_nickname
        client.puts 'R' + @spacer + 'F'
        return
      end
    end
    File.open('clients.txt', 'a+') do |clients_file|
      clients_file.puts "#{nickname} #{login_password[1]}"
    end
    puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} new user: #{nickname}"
    time = Time.now.strftime("%H:%M:%S")
    @connections.each_value do |other_client|
      other_client.puts 'M' + @spacer + "#{time} #{nickname} has joined the chat!"
    end
    @connections[nickname] = client
    @clients[nickname] = login_password[1]
    client.puts 'R' + @spacer + 'Enjoy the chat!'
  end

  def send_to_all(message, client)
    response = 'M' + @spacer + message
    @connections.each_value do |other_client|
      unless other_client == client
        other_client.puts response
      end
    end
    puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} new message"
  end

  def client_left(message, client)
    nickname = message.to_sym
    @connections.reject! { |key| key == nickname }
    puts "#{Time.now.strftime("%-d/%-m/%y %H:%M:%S")} client #{nickname} was deleted"
    client.puts 'E' + @spacer + 'Goodbye!'
    client.close
    message_to_all = 'M' + @spacer + "#{nickname} has left the chat!"
    @connections.each_value do |other_client|
        other_client.puts message_to_all
    end
    Thread.kill self
  end

  def authorize(message, client)
    nickname_password = message.split
    nickname = nickname_password[0].to_sym
    password = nickname_password[1]
    if @clients[nickname] != password
      client.puts 'A' + @spacer + 'F'
      return
    end
    time = Time.now.strftime("%H:%M:%S")
    @connections.each_value do |other_client|
      other_client.puts 'M' + @spacer + "#{time} #{nickname} has joined the chat!"
    end
    @connections[nickname] = client
    client.puts 'A' + @spacer + 'you successfully authorized!'
  end
end

server = Server.new('localhost', 60231)
