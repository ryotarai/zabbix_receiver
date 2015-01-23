require 'spec_helper'
require 'logger'

describe ZabbixReceiver::Worker do
  subject(:worker) do
    double(:worker).extend(described_class)
  end

  let(:output) { double(:output) }
  let(:config) { {
    proxy_to_host: 'zabbix-server',
    proxy_to_port: 'port',
  } }

  before do
    allow(worker).to receive(:logger).and_return(Logger.new(open('/dev/null', 'w')))
    allow(worker).to receive(:output).and_return(output)
    allow(worker).to receive(:config).and_return(config)
  end

  describe "#process" do
    context "with sender data" do
      let(:request) { "ZBXD\u0001b\u0000\u0000\u0000\u0000\u0000\u0000\u0000{\n\t\"request\":\"sender data\",\n\t\"data\":[\n\t\t{\n\t\t\t\"host\":\"hello\",\n\t\t\t\"key\":\"key\",\n\t\t\t\"value\":\"value\"}]}" }
      it "receives sender data" do
        expect(output).to receive(:receive_sender_data).with({"request"=>"sender data", "data"=>[{"host"=>"hello", "key"=>"key", "value"=>"value"}]})

        io = StringIO.new(request.dup)

        worker.process(io)
        expected_response = "ZBXD\u0001S\u0000\u0000\u0000\u0000\u0000\u0000\u0000{\"response\":\"success\",\"info\":\"Processed 1 Failed 0 Total 1 Seconds spent 0.000000\"}"
        expect(io.string).to eq(request + expected_response)
      end
    end

    context "with active checks" do
      let(:socket_to_zabbix_server) { double(:socket) }
      let(:request) { "ZBXD\u0001)\x00\x00\x00\x00\x00\x00\x00{\"request\":\"active checks\",\"key\":\"value\"}" }
      let(:response) { "response_from_zabbix_server" }

      it "proxies a request to zabbix server" do
        io = StringIO.new(request.dup)

        expect(TCPSocket).to receive(:open).
          with('zabbix-server', 'port').
          and_return(socket_to_zabbix_server)
        expect(socket_to_zabbix_server).to receive(:close)
        expect(socket_to_zabbix_server).to receive(:write).with(request)
        expect(socket_to_zabbix_server).to receive(:read).and_return(response)

        worker.process(io)
      end
    end
  end
end

