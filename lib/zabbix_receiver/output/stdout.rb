module ZabbixReceiver
  module Output
    class Stdout
      def self.parse_options(argv)
        {}
      end

      def initialize(logger, options)
      end

      def receive_sender_data(data)
        puts data
      end
    end
  end
end
