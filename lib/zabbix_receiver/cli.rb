require 'zabbix_receiver'
require 'serverengine'
require 'optparse'

module ZabbixReceiver
  class CLI
    REQUIRED_OPTIONS = %i(daemonize workers proxy_to_host proxy_to_port bind port)

    def self.start(argv)
      self.new(argv).start
    end

    def initialize(argv)
      load_options(argv)
    end

    def start
      options = {
        worker_type: 'process',
      }.merge(@options)

      se = ServerEngine.create(Server, Worker, options)
      se.run
    end

    private

    def load_options(argv)
      @options = {
        daemonize: false,
        workers: 1,
        bind: '0.0.0.0',
        port: 10051,
        proxy_to_port: 10051,
        to: 'stdout',
      }

      parser = OptionParser.new
      parser.on('--daemonize') {|v| @options[:daemonize] = true }
      parser.on('--log=VAL', 'default: STDERR') {|v| @options[:log] = v }
      parser.on('--pid-path=VAL') {|v| @options[:pid_path] = v }
      parser.on('--workers=VAL') {|v| @options[:worker] = v }
      parser.on('--bind=VAL') {|v| @options[:bind] = v }
      parser.on('--port=VAL') {|v| @options[:port] = v }
      parser.on('--proxy-to-host=VAL') {|v| @options[:proxy_to_host] = v }
      parser.on('--proxy-to-port=VAL') {|v| @options[:proxy_to_port] = v }
      parser.on('--to=VAL') {|v| @options[:to] = v }
      parser.on('--log-level=VAL') {|v| @options[:log_level] = v }
      parser.parse!(argv)

      REQUIRED_OPTIONS.each do |key|
        unless @options.has_key?(key)
          raise "--#{key.to_s.split('_').join('-')} option is required."
        end
      end
    end
  end
end
