require 'spec_helper'

module Bookbinder
  describe Cli do
    include_context 'tmp_dirs'

    let(:cli) { Cli.new }
    let(:cred_repo) { 'fantastic/creds-repo' }
    let(:logger) { NilLogger.new }

    around_with_fixture_repo &:run

    def run
      cli.run arguments
    end

    before do
      allow(BookbinderLogger).to receive(:new).and_return(logger)
      allow(logger).to receive(:log)
      allow(logger).to receive(:error)
    end

    describe '#run' do
      Cli::COMMANDS.each do |klass|
        let(:extra_args) { ['arg1', 'arg2'] }
        let(:fake_command) { double }

        context "running the #{klass.command_name} command" do
          let(:arguments) { [klass.command_name] + extra_args }

          before do
            allow(klass).to receive(:new).and_return(fake_command)
          end

          it "calls run #{klass} for the #{klass.command_name} command" do
            expect(fake_command).to receive(:run).with(['arg1', 'arg2'])
            cli.run arguments
          end

          it "returns the return value of #{klass} for the #{klass.command_name} command" do
            expect(fake_command).to receive(:run).and_return(42)
            expect(cli.run arguments).to eq(42)
          end
        end
      end

      context 'when no arguments are supplied' do
        let(:arguments) { [] }
        it 'should print a helpful message' do
          expect(logger).to receive(:log).with(/Unrecognized command ''/)
          run
        end
      end

      context 'when a command that is not recognized is supplied' do
        let(:arguments) { ['foo'] }
        it 'should print a helpful message' do
          expect(logger).to receive(:log).with(/Unrecognized command 'foo'/)
          run
        end
      end

      context 'when run raises' do
        context 'a KeyError' do
          before do
            allow_any_instance_of(Cli::Publish).to receive(:run).and_raise KeyError.new 'I broke'
          end

          let(:arguments) { ['publish', 'local'] }

          it 'logs the error with the config file name' do
            expect(logger).to receive(:error).with(/I broke.*your configuration/)
            run
          end

          it 'should return 1' do
            expect(run).to eq 1
          end
        end

        context 'a Configuration::CredentialKeyError' do
          before do
            allow_any_instance_of(Cli::Publish).to receive(:run).and_raise Configuration::CredentialKeyError.new 'I broke'
          end

          let(:arguments) { ['publish', 'local'] }

          it 'logs the error with the credentials file name' do
            expect(logger).to receive(:error).with(/I broke.*in credentials\.yml/)
            run
          end

          it 'should return 1' do
            expect(run).to eq 1
          end
        end

        context 'for InvalidArguments' do
          before do
            allow_any_instance_of(Cli::Publish).to receive(:run).and_raise Cli::InvalidArguments.new
          end

          let(:arguments) { ['publish', 'local'] }

          it 'shows the command usage' do
            expect(logger).to receive(:log).with(Cli::Publish.usage)
            run
          end

          it 'should return 1' do
            expect(run).to eq 1
          end
        end

        context 'any other error' do
          before do
            allow_any_instance_of(Cli::Publish).to receive(:run).and_raise 'I broke'
          end

          let(:arguments) { ['publish', 'local'] }

          it 'logs the error message' do
            expect(logger).to receive(:error).with(/I broke/)
            run
          end

          it 'should return 1' do
            expect(run).to eq 1
          end
        end
      end

      context 'when config.yml is empty' do
        before do
          allow(File).to receive(:read)
          allow(YAML).to receive(:load).and_return(false)
        end

        let(:arguments) { ['publish', 'local'] }

        it 'should print a helpful message' do
          expect(logger).to receive(:error).with(/config.yml appears to be empty/)
          run
        end
      end

      context 'when config.yml has a syntax error' do
        let(:arguments) { ['publish', 'local'] }
        let(:config) { double File }
        let(:file_path) { double String }

        before do
          allow(config).to receive(:read).with(file_path).and_return(config)
          allow(YAML).to receive(:load).and_raise Psych::SyntaxError.new(
                                                      'context',
                                                      1,
                                                      2,'
                                                      error',
                                                      'another error',
                                                      'some other error'
                                                  )
        end

        it 'should print a helpful message' do
          expect(logger).to receive(:error).with(/There is a syntax error in your config file/)
          run
        end
      end

      describe 'the configuration' do
        let(:section1) do
          {
              'repository' => {
                  'name' => 'foo/dogs-repo'
              },
              'directory' => 'concepts'
          }
        end

        let(:config_hash) do
          {
              cool: 'config',
              'sections' => [section1],
              'public_host' => 'http://example.com'
          }
        end

        before { File.write('./config.yml', config_hash.to_yaml) }

        context 'when the configuration is invalid' do
          # this test will get fixed by the config_validator
          let(:config_hash) { {cool: 'config', 'sections' => [section1, section1]} }
          it 'logs an error' do
            expect(logger).to receive(:error).with(anything)
            cli.run ['publish', 'local']
          end
        end
      end
    end

    describe 'flags' do
      context 'when the input flag is --version' do
        it 'should log the gemspec version' do
          expect(logger).to receive(:log).with("bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}")
          expect(cli.run ['--version']).to eq(0)
        end

        it 'the flag is added to the usage list' do
          expect(logger).to receive(:log).with(/--#{Regexp.escape('version')}/)
          cli.run []
        end
      end

      context 'when a flag that is not recognized is supplied' do
        let(:arguments) { ['--foo'] }

        it 'should print a helpful message' do
          expect(logger).to receive(:log).with(/Unrecognized flag '--foo'/)
          run
        end
      end
    end
  end
end
