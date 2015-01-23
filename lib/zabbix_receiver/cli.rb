require 'zabbix_receiver'
require 'serverengine'
require 'slop'

module ZabbixReceiver
  class CLI
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
      output_type = argv.first
      output_class = get_output_class(output_type)
      if output_class
        argv.shift # output type
      else
        output_type = 'stdout'
        output_class = get_output_class(output_type)
      end

      puts "Using #{output_type} output."

      opts = Slop::Options.new
      opts.on('--help') { puts opts; exit }
      opts.bool '--daemonize', default: false
      opts.string '--log'
      opts.string '--pid-path'
      opts.integer '--workers', default: 1
      opts.string '--bind', default: '0.0.0.0'
      opts.integer '--port', default: 10051
      opts.string '--proxy-to-host'
      opts.integer '--proxy-to-port', default: 10051
      opts.string '--log-level'
      output_class.add_options(opts)

      parser = Slop::Parser.new(opts)
      @options = Hash[parser.parse(argv).to_hash.map do |k, v|
        [k.to_s.tr('-', '_').to_sym, v]
      end]

      @options[:output_class] = output_class
    end

    def get_output_class(type)
      require "zabbix_receiver/output/#{type}"
      class_name = type.split('_').map {|v| v.capitalize }.join
      ZabbixReceiver::Output.const_get(class_name)
    rescue NameError, LoadError
      nil
    end
  end
end
