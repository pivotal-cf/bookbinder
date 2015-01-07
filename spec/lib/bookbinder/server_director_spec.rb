require 'spec_helper'

module Bookbinder
  describe ServerDirector do
    include_context 'tmp_dirs'

    let(:port) { 8000 }
    let(:server_directory) { tmp_subdir 'server_directory' }
    let(:logger) { NilLogger.new }
    let(:server_director) { ServerDirector.new(logger, directory: server_directory, port: port) }

    before do
      Dir.chdir(server_directory) do
        File.open('config.ru', 'w') do |f|
          f.write(<<-HERE)
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
      let(:stdout_stream) { double }
      let(:fake_pid) { 10 }

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
        let(:server_director) { ServerDirector.new(logger, directory: server_directory) }

        it 'defaults to 41722' do
          expect(POpen4).to receive(:popen4).with('puma -p 41722')
          server_director.use_server {}
        end
      end

      context 'when the server does not start successfully' do
        it 'raises an error' do
          allow(Process).to receive(:kill)
          allow(POpen4).to receive(:popen4) do |&blk|
            allow(stdout_stream).to receive(:gets).and_return(nil)
            blk.call(stdout_stream, nil, nil, fake_pid)
          end

          expect { server_director.use_server {} }.to raise_error('Puma could not start')
        end
      end
    end

    describe 'passing in a block' do
      let(:inner_worker) { double }
      let(:stdout_stream) { double }

      it 'executes it and passes the port' do
        expect { |b|
          server_director.use_server &b
        }.to yield_with_args(port)
      end

      it 'does not execute it until the server has started' do
        allow(Process).to receive(:kill)
        allow(POpen4).to receive(:popen4) do |&blk|
          blk.call(stdout_stream, nil, nil, nil)
        end

        expect(Kernel).to receive(:sleep).with(1)

        expect(stdout_stream).to receive(:gets).and_return('Waiting', 'Waiting', 'Listening on').ordered
        expect(inner_worker).to receive(:do_work).ordered

        server_director.use_server { inner_worker.do_work }
      end
    end


    describe 'stopping the server' do
      let(:stdout_stream) { double(gets: 'Listening on') }
      let(:server_pid) { 5252 }

      it 'stops' do

        allow(POpen4).to receive(:popen4) do |&blk|
          blk.call(stdout_stream, nil, nil, server_pid)
        end

        expect(Process).to receive(:kill).with('KILL', server_pid)
        server_director.use_server {}
      end
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
end
