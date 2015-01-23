module ZabbixReceiver
  module Output
    class Stdout
      def self.add_options(opts)
        opts.string '--indent', default: ''
      end

      def initialize(logger, options)
        @options = options
      end

      def receive_sender_data(data)
        puts @options[:indent] + data.inspect
      end
    end
  end
end
