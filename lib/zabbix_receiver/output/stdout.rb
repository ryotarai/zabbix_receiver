module ZabbixReceiver
  module Output
    class Stdout
      def receive_sender_data(data)
        puts data
      end
    end
  end
end
