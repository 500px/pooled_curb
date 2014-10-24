require 'spec_helper'

describe Service::PooledCurb do
  subject { Service::PooledCurb }
  before(:each) { subject.reset! }

  describe '.configure' do
    let(:expected_value) { rand(1..1000) }

    def do_configure(attr_name, value)
      subject.configure do |client|
        client.send("#{attr_name}=", value)
      end
    end

    %w(pool_size pool_timeout read_timeout write_timeout).each do |attr_name|
      it "sets #{attr_name}" do
        do_configure(attr_name, expected_value)
        expect(subject.send(attr_name)).to eq(expected_value)
      end
    end
  end

  describe '.connection_pool' do
    it "returns an instance of ConnectionPool" do
      expect(subject.connection_pool).to be_a(ConnectionPool)
    end
  end

  describe '.get' do
    let(:curl) { Curl::Easy.new }

    before :each do
      curl.stub(:http_get)
      curl.stub(:http_post)
      subject.stub(:with_client).and_yield(curl)
    end

    it "configures default timeout on request" do
      expect(curl).to receive("timeout=").with(Service::PooledCurb::READ_TIMEOUT)
      subject.get("stub")
    end

    it "configures custom timeout on request" do
      expected_timeout = rand(0..1000)

      subject.configure { |client| client.read_timeout = expected_timeout }
      expect(curl).to receive("timeout=").with(expected_timeout)

      subject.get("stub")
    end

    it "sets the URL of the request" do
      expected_url = "http://stub#{rand(0..1000)}"

      expect(curl).to receive("url=").with(expected_url)
      subject.get(expected_url)
    end

    it "makes a GET request" do
      expect(curl).to receive(:http_get).once
      subject.get("stub")
    end

    context "returning response" do
      let(:response_json) { {"value" => "stub-response-#{rand(0..100_000)}"} }
      let(:stub_response) { response_json.to_json }
      let(:header_str) { "HTTP/1.1 200 OK\r\nContent-Length: 19\r\nContent-Type: text/plain; charset=utf-8\r\nDate: Mon, 02 Jun 2014 14:04:16 GMT\r\n\r\n" }

      before :each do
        curl.stub(:body_str).and_return(stub_response)
        curl.stub(:header_str).and_return(header_str)

        curl.stub(:response_code).and_return(200)
      end

      it "returns a Response object" do
        expect(subject.get("stub")).to be_a(Service::PooledCurb::Response)
      end

      it "sets body_str on Response object" do
        expect(subject.get("stub").body).to be(stub_response)
      end

      it "sets status on Response object" do
        expect(subject.get("stub").status).to be(200)
      end

      it "sets header_str on Response object" do
        expect(subject.get("stub").header_str).to be(header_str)
      end

      context "with the headers" do
        it "parses into a hash" do
          expect(subject.get("stub").headers).to be_a(Hash)
        end

        it "parses all the headers" do
          expect(subject.get("stub").headers.size).to eq(3)
        end

        it "splits on the first colon only" do
          expect(subject.get("stub").headers["Content-Length"]).to eq("19")
          expect(subject.get("stub").headers["Content-Type"]).to eq("text/plain; charset=utf-8")
          expect(subject.get("stub").headers["Date"]).to eq("Mon, 02 Jun 2014 14:04:16 GMT")
        end
      end

      it "sets status on Response object" do
        expect(subject.get("stub").status).to be(200)
      end
    end

    context "request takes too long" do
      let(:expected_error) { Curl::Err::TimeoutError.new }

      before :each do
        curl.stub(:http_get).and_raise(expected_error)
      end

      it "raises the exception" do
        expect {
          subject.get("stub")
        }.to raise_error(expected_error)
      end
    end
  end


  describe '.post' do
    let(:curl) { Curl::Easy.new }

    before :each do
      curl.stub(:http_post)
      subject.stub(:with_client).and_yield(curl)
    end

    it "configures default timeout on request" do
      expect(curl).to receive("timeout=").with(Service::PooledCurb::WRITE_TIMEOUT)
      subject.post("stub", {})
    end

    it "configures custom timeout on request" do
      expected_timeout = rand(0..1000)

      subject.configure { |client| client.write_timeout = expected_timeout }
      expect(curl).to receive("timeout=").with(expected_timeout)

      subject.post("stub", {})
    end

    it "sets the URL of the request" do
      expected_url = "http://stub#{rand(0..1000)}"

      expect(curl).to receive("url=").with(expected_url)
      subject.post(expected_url, {})
    end

    it "sets the POST body" do
      expect(curl).to receive(:http_post).once do |args|
        expect(args.first.name).to eq(:x)
        expect(args.first.content).to eq(27)
      end
      subject.post("stub", {x: 27})
    end

    it "makes a POST request" do
      expect(curl).to receive(:http_post).once
      subject.post("stub", {})
    end

    context "returning response" do
      let(:response_json) { {"value" => "stub-response-#{rand(0..100_000)}"} }
      let(:stub_response) { response_json.to_json }
      let(:header_str) { "HTTP/1.1 200 OK\r\nContent-Length: 19\r\nContent-Type: text/plain; charset=utf-8\r\nDate: Mon, 02 Jun 2014 14:04:16 GMT\r\n\r\n" }

      before :each do
        curl.stub(:body_str).and_return(stub_response)
        curl.stub(:header_str).and_return(header_str)

        curl.stub(:response_code).and_return(200)
      end

      it "returns a Response object" do
        expect(subject.post("stub", {})).to be_a(Service::PooledCurb::Response)
      end

      it "sets body_str on Response object" do
        expect(subject.post("stub", {}).body).to be(stub_response)
      end

      it "sets status on Response object" do
        expect(subject.post("stub", {}).status).to be(200)
      end

      it "sets header_str on Response object" do
        expect(subject.post("stub", {}).header_str).to be(header_str)
      end

      context "with the headers" do
        it "parses into a hash" do
          expect(subject.post("stub", {}).headers).to be_a(Hash)
        end

        it "parses all the headers" do
          expect(subject.post("stub", {}).headers.size).to eq(3)
        end

        it "splits on the first colon only" do
          expect(subject.post("stub", {}).headers["Content-Length"]).to eq("19")
          expect(subject.post("stub", {}).headers["Content-Type"]).to eq("text/plain; charset=utf-8")
          expect(subject.post("stub", {}).headers["Date"]).to eq("Mon, 02 Jun 2014 14:04:16 GMT")
        end
      end

      it "sets status on Response object" do
        expect(subject.post("stub", {}).status).to be(200)
      end
    end
  end
end
