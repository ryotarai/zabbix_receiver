require 'spec_helper'

describe ZabbixReceiver::Server do
  let(:options) { {
    proxy_to: {
      host: 'zabbix-server',
      port: 'port',
    }
  } }
  subject(:server) { described_class.new(options) }

  describe '#accept' do
    context 'with sender data' do
      let(:request) { "ZBXD\u0001b\u0000\u0000\u0000\u0000\u0000\u0000\u0000{\n\t\"request\":\"sender data\",\n\t\"data\":[\n\t\t{\n\t\t\t\"host\":\"hello\",\n\t\t\t\"key\":\"key\",\n\t\t\t\"value\":\"value\"}]}" }

      it 'receives sender data' do
        io = StringIO.new(request.dup)

        received_data = nil
        server.on_receive_sender_data do |data|
          received_data = data
        end

        server.accept(io)
        expected_response = "ZBXD\u0001S\u0000\u0000\u0000\u0000\u0000\u0000\u0000{\"response\":\"success\",\"info\":\"Processed 1 Failed 0 Total 1 Seconds spent 0.000000\"}"
        expect(io.string).to eq(request + expected_response)
        expect(received_data).to eq({
          'request' => 'sender data',
          'data' => [{
            'host'  => 'hello',
            'key'   => 'key',
            'value' => 'value',
          }],
        })
      end
    end

    context 'with active checks' do
      let(:socket_to_zabbix_server) { double(:socket) }
      let(:request) { "ZBXD\u0001)\x00\x00\x00\x00\x00\x00\x00{\"request\":\"active checks\",\"key\":\"value\"}" }
      let(:response) { "response_from_zabbix_server" }

      it 'proxies a request to zabbix server' do
        allow(socket_to_zabbix_server).to receive(:seek)

        expect(TCPSocket).to receive(:open).with('zabbix-server', 'port').and_return(socket_to_zabbix_server)
        expect(socket_to_zabbix_server).to receive(:close)
        expect(socket_to_zabbix_server).to receive(:write).with(request)
        expect(socket_to_zabbix_server).to receive(:read).and_return(response)

        io = StringIO.new(request.dup)
        server.accept(io)
        expect(io.string).to eq(request + response)
      end
    end
  end
end
