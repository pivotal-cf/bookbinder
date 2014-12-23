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
      Cli::COMMAND_TO_CLASS_MAPPING.each do |command, klass|
        let(:extra_args) { ['arg1', 'arg2'] }
        let(:fake_command) { double }

        context "running the #{command} command" do
          let(:arguments) { [command] + extra_args }

          before do
            allow(klass).to receive(:new).and_return(fake_command)
          end

          it "calls run #{klass} for the #{command} command" do
            expect(fake_command).to receive(:run).with(['arg1', 'arg2'])
            cli.run arguments
          end

          it "returns the return value of #{klass} for the #{command} command" do
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
            expect(logger).to receive(:log).with(/publish #{Regexp.escape(Cli::Publish.usage)}/)
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
    end

    describe 'flags' do
      Cli::FLAGS.each do |flag|
        let(:arguments) { ["--#{flag}"] }

        context "calling the #{flag} flag" do
          it "calls the #{flag} method on cli" do
            expect(cli).to receive(flag.to_sym)
            run
          end

          it 'returns 0' do
            expect(run).to eq(0)
          end
        end

        it "the #{flag} is added to the usage list" do
          expect(logger).to receive(:log).with(/--#{Regexp.escape(flag)}/)
          cli.run ['--foo']
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