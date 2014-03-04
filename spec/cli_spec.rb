require 'spec_helper'

describe Cli do
  include_context 'tmp_dirs'

  let(:cli) { Cli.new }
  let(:cred_repo) { 'fantastic/creds-repo' }

  around_with_fixture_repo &:run

  describe '#run' do
    def run
      cli.run arguments
    end

    Cli::COMMAND_TO_CLASS_MAPPING.each do |command, klass|
      let(:extra_args) { ['arg1', 'arg2'] }
      let(:fake_command) { double }

      context "running the #{command} command" do
        let(:arguments) { [command] + extra_args }

        before do
          klass.stub(:new).and_return(fake_command)
        end

        it "calls run #{klass} for the #{command} command" do
          fake_command.should_receive(:run).with(['arg1', 'arg2'])
          cli.run arguments
        end

        it "returns the return value of #{klass} for the #{command} command" do
          fake_command.should_receive(:run).and_return(42)
          expect(cli.run arguments).to eq(42)
        end
      end
    end

    context 'when no arguments are supplied' do
      let(:arguments) { [] }
      it 'should print a helpful message' do
        BookbinderLogger.should_receive(:log).with(/Unrecognized command ''/)
        run
      end
    end

    context 'when a command that is not recognized is supplied' do
      let(:arguments) { ['foo'] }
      it 'should print a helpful message' do
        BookbinderLogger.should_receive(:log).with(/Unrecognized command 'foo'/)
        run
      end
    end

    context 'when run raises' do
      context 'a KeyError' do
        before do
          Cli::Publish.any_instance.stub(:run).and_raise KeyError.new 'I broke'
        end

        let(:arguments) { ['publish', 'local'] }

        it 'logs the error with the config file name' do
          BookbinderLogger.should_receive(:log).with(/I broke.*in config\.yml/)
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end

      context 'a Cli::CredentialKeyError' do
        before do
          Cli::Publish.any_instance.stub(:run).and_raise Cli::CredentialKeyError.new 'I broke'
        end

        let(:arguments) { ['publish', 'local'] }

        it 'logs the error with the credentials file name' do
          BookbinderLogger.should_receive(:log).with(/I broke.*in credentials\.yml/)
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end

      context 'for InvalidArguments' do
        before do
          Cli::Publish.any_instance.stub(:run).and_raise Cli::InvalidArguments.new
        end

        let(:arguments) { ['publish', 'local'] }

        it 'shows the command usage' do
          expect(BookbinderLogger).to receive(:log).with(/publish #{Regexp.escape(Cli::Publish.usage)}/)
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end

      context 'any other error' do
        before do
          Cli::Publish.any_instance.stub(:run).and_raise 'I broke'
        end

        let(:arguments) { ['publish', 'local'] }

        it 'logs the error message' do
          BookbinderLogger.should_receive(:log).with(/I broke/)
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end
    end

    context 'when config.yml is empty' do
      before do
        File.stub(:read)
        YAML.stub(:load).and_return(false)
      end

      let(:arguments) { ['publish', 'local'] }

      it 'should print a helpful message' do
        BookbinderLogger.should_receive(:log).with(/config.yml is empty/)
        run
      end
    end

    describe 'the configuration' do
      let(:config_hash) { {cool: 'config', without: 'credentials'} }
      let(:configuration) { Configuration.new(config_hash) }

      before { File.write('./config.yml', config_hash.to_yaml) }

      it 'passes configuration to the given command' do
        expect(Cli::Publish).to receive(:new).with(configuration)
        cli.run ['publish', 'local']
      end
    end
  end
end
