require 'spec_helper'

describe ServerDirector do
  include_context 'tmp_dirs'

  let(:port) { 8000 }
  let(:server_directory) { tmp_subdir 'server_directory' }
  let(:server_director) { ServerDirector.new(directory: server_directory, port: port) }

  before do
    Dir.chdir(server_directory) do
      File.open('config.ru', 'w') do |f|
        f.write(<<HERE)
require 'rack/static'

class MyApp < Rack::Static
  puts 'Hello, World!'
end

run MyApp
HERE
      end
    end
  end

  describe 'starting the server' do

    it 'starts it in the given directory' do
      expect(POpen4).to receive(:popen4) do
        expect(Pathname.new(Dir.pwd).realpath).to eq(Pathname.new(server_directory).realpath)
      end
      server_director.use_server {}
    end

    it 'starts it on the given port' do
      expect(POpen4).to receive(:popen4).with("puma -p #{port}")
      server_director.use_server {}
    end

    context 'when no port is given' do
      let(:server_director) { ServerDirector.new(directory: server_directory) }

      it 'defaults to 41722' do
        expect(POpen4).to receive(:popen4).with('puma -p 41722')
        server_director.use_server {}
      end
    end

    context 'when the server does not start successfully' do
      it 'raises an error' do
        allow(Process).to receive(:kill)
        allow(POpen4).to receive(:popen4) do |&blk|
          fake_pid = 10
          fake_stdout = double
          allow(fake_stdout).to receive(:gets).and_return(nil)
          blk.call(fake_stdout, nil, nil, fake_pid)
        end

        expect { server_director.use_server {} }.to raise_error('Puma could not start')
      end
    end
  end

  describe 'passing in a block' do
    it 'executes it and passes the port' do
      expect { |b|
        server_director.use_server &b
      }.to yield_with_args(port)
    end

    it 'does not execute it until the server has started' do
      inner_worker = double
      fake_stdout = double

      allow(Process).to receive(:kill)
      allow(POpen4).to receive(:popen4) do |&blk|
        blk.call(fake_stdout, nil, nil, nil)
      end

      expect(fake_stdout).to receive(:gets).and_return('Waiting', 'Waiting', 'Listening on').ordered
      expect(inner_worker).to receive(:do_work).ordered

      server_director.use_server { inner_worker.do_work }
    end
  end

  it 'stops the server' do
    fake_stdout = double(gets: 'Listening on')
    server_pid = 5252

    allow(POpen4).to receive(:popen4) do |&blk|
      blk.call(fake_stdout, nil, nil, server_pid)
    end

    expect(Process).to receive(:kill).with('KILL', server_pid)
    server_director.use_server {}
  end

  describe 'when the passed-in block raises an exception' do
    it 'still stops the server' do
      expect(Process).to receive(:kill)

      expect {
        server_director.use_server { raise 'Custom error' }
      }.to raise_error('Custom error')
    end
  end
end
