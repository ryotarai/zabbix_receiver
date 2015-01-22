require 'json'
require 'logger'

module ZabbixReceiver
  class Server
    ZABBIX_HEADER = "ZBXD\x01"

    def initialize(options = {})
      @options = {
        proxy_to: {
          port: 10051,
        },
      }.merge(options)

      validate_options

      @logger = options[:logger] || Logger.new(StringIO.new)

      @blocks_on_receive_sender_data = []
    end

    def on_receive_sender_data(&block)
      @blocks_on_receive_sender_data << block
    end

    def start(address, port)
      server = TCPServer.open(address, port)

      while true
        Thread.start(server.accept) do |f|
          accept(f)
        end
      end
    end

    def accept(f)
      request = parse(f)

      @logger.debug "Request: #{request}"

      request_type = request['request']

      case request_type
      when 'active checks'
        proxy_request(f)
      when 'sender data'
        @blocks_on_receive_sender_data.each do |block|
          block.call(request)
        end

        count = request['data'].size

        respond_with(f, {
          "response" => "success",
          "info" => "Processed #{count} Failed 0 Total #{count} Seconds spent 0.000000"
        })
      else
        @logger.error "Unknown request type (#{request_type})"
      end
    ensure
      f && f.close
    end

    def proxy_request(f)
      f.seek(0)

      socket = TCPSocket.open(
        @options[:proxy_to][:host],
        @options[:proxy_to][:port],
      )
      socket.write(f.read)
      f.write(socket.read)
    ensure
      socket && socket.close
    end

    private

    def parse(f)
      f.seek(0)

      unless f.read(5) == ZABBIX_HEADER
        @logger.error "Invalid Zabbix request"
        return
      end

      length = f.read(8).unpack('q').first
      body = f.read
      unless body.size == length
        @logger.error "Length mismatch"
        return
      end

      JSON.parse(body)
    end

    def respond_with(f, payload)
      payload = payload.to_json
      f.write(ZABBIX_HEADER + [payload.bytesize].pack('q') + payload)
    end

    def validate_options
      [:host, :port].each do |k|
        unless @options[:proxy_to][k]
          raise "options[:proxy_to][:#{k}] is required."
        end
      end
    end
  end
end

