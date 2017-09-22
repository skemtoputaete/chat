# encoding: UTF-8
require 'thread'
require 'socket'

class Server
  def initialize(ip, port)
    @server = TCPServer.open(ip, port)
    @mutex = Mutex.new
    @connections = {}
    @clients = {}
    @spacer = 0.chr
    run
  end

  private
    def run
      loop do
        Thread.start(@server.accept) do |client|
          puts 'Connection accepted.'
          get_message(client)
        end
      end
    end

    # register_client(client, login_password)
    # This method registers a new client
    # login_password[0] is login
    # login_password[1] is password
    def register_client(client, login_password)
      pair = login_password.split
      @mutex.synchronize do
        @connections.each do |existed_client, existed_nickname|
          if existed_client == client || existed_nickname == pair[0]
            client.puts 'R' + @spacer + 'F' + @spacer + 'This username already exist.'
            Thread.kill self
          end
        end
        @connections[client] = pair[0]
        @clients[pair[0]] = pair[1]
      end
      puts Time.now.to_s + " Client with nickname #{pair[0]} has been registered."
      client.puts 'R' + @spacer + 'S' + @spacer + 'Your sign up successfull!'
    end

    # check_client(client, login_password)
    # This method checks user's login and password
    # login_password[0] is login
    # login_password[1] is password
    def check_client(client, login_password)
      pair = login_password.split
      @mutex.synchronize do
        if @clients[pair[0]].nil?
          client.puts 'A' + @spacer + "Client with this nickname doesn't exist."
          Thread.kill self
        end
        unless @clients[pair[0]] == pair[1]
          client.puts 'A' + @spacer + 'Wrong password.'
          Thread.kill self
        end
        if @connections[client].nil?
          @connections[client] = pair[0]
        end
      end
      puts Time.now.to_s = "Client with nickname #{pair[1]} has been authorized."
      client.puts 'R' + @spacer + 'You log in successfull!'
      @mutex.synchronize do
        @connections.each_key do |other_client|
          unless other_client == client
            other_client.puts 'M' + @spacer + "#{pair[1]} joined the chat."
          end
        end
      end
    end

    # send_client_message(client, message)
    # This method sends message of one client to other
    def send_client_message(client, message)
      @mutex.synchronize do
        nickname = @connections[client]
        @connections.each_key do |other_client|
          unless other_client == client
            other_client.puts 'M' + @spaces + nickname + ': ' + message
          end
        end
      end
    end

    # client_left(client)
    # This method informs all clients that someone has left the chat
    def client_left(client)
      @mutex.synchronize do
        nickname = @connections[client]
        @connections.delete(client)
        @connections.each_key do |c|
          c.puts 'M' + @spaces + nickname + ' left the chat.'
        end
      end
    end

    # get_message(client) - gets a message from the client
    # Handle client's message
    # Client sends a message with one char in the beginning
    # This char separated by 0.chr
    # Below meanings of these chars:
    # C - check the connection
    # R - client tries to register
    # A - client tries to log in
    # M - client sends a message
    # E - client left the cha
    def get_message(client)
      loop do
        message = client.gets.chomp
        pair = message.split(@spacer)
        case pair[0]
        when 'C'
          client.puts 'C' + @spacer + 'Connection is OK.'
        when 'R'
          register_client(client, pair[1])
        when 'A'
          check_client(client, pair[1])
        when 'M'
          send_client_message(client, pair[1])
        when 'E'
          puts "#{message[1]}"
        end
      end
    end
end

server = Server.new('localhost', 60231)
