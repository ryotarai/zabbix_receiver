require 'json'

module ZabbixReceiver
  module Worker
    ZABBIX_HEADER = "ZBXD\x01"

    def output
      @output ||= config[:output_class].new(logger, config)
    end

    def run

      until @stop
        process(server.sock.accept)
      end
    end

    def stop
      @stop = true
    end

    def process(c)
      request_body = c.read
      request = parse(request_body)
      logger.debug "Request: #{request}"
      request_type = request['request']

      case request_type
      when 'active checks'
        response_body = proxy_request(request_body)
      when 'sender data'
        output.receive_sender_data(request)

        count = request['data'].size

        response_body = format_response({
          "response" => "success",
          "info" => "Processed #{count} Failed 0 Total #{count} Seconds spent 0.000000"
        })
      else
        logger.error "Unknown request type (#{request_type})"
        response_body = format_response({
          "response" => "success",
          "info" => ""
        })
      end

      logger.debug "Raw response: #{response.inspect}"
      c.write(response_body)
    ensure
      c.close
    end

    def proxy_request(request_body)
      socket = TCPSocket.open(
        config[:proxy_to_host],
        config[:proxy_to_port],
      )
      socket.write(request_body)
      socket.read
    ensure
      socket && socket.close
    end

    private

    def parse(request_body)
      request = StringIO.new(request_body)

      unless request.read(5) == ZABBIX_HEADER
        logger.error "Invalid Zabbix request"
        return
      end

      length = request.read(8).unpack('q').first
      body = request.read
      unless body.size == length
        logger.error "Length mismatch"
        return
      end

      JSON.parse(body)
    end

    def format_response(payload)
      payload = payload.to_json
      ZABBIX_HEADER + [payload.bytesize].pack('q') + payload
    end
  end
end
