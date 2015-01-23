module ZabbixReceiver
  module Server
    attr_reader :sock

    def before_run
      bind = config[:bind]
      port = config[:port]

      logger.info "Listening on #{bind}:#{port}..."

      @sock = TCPServer.open(bind, port)
    end
  end
end

