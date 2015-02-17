require_relative '../../../lib/bookbinder/cli'
require_relative '../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe Cli do
    let(:cli) { Cli.new }
    let(:cred_repo) { 'fantastic/creds-repo' }
    let(:logger) { NilLogger.new }

    use_fixture_repo

    def run
      cli.run arguments
    end

    before do
      allow(BookbinderLogger).to receive(:new).and_return(logger)
      allow(logger).to receive(:log)
      allow(logger).to receive(:error)
    end

    context 'when no arguments are supplied' do
      let(:arguments) { [] }
      it 'should print a helpful message' do
        expect(logger).to receive(:log).with(/Usage/)
        run
      end
    end

    context 'when a command that is not recognized is supplied' do
      let(:arguments) { ['foo'] }
      it 'should print a helpful message' do
        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          expect(run).to eq(1)

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to match(/Unrecognized command 'foo'/)

        ensure
          $stdout = real_stdout
        end
      end
    end

    context 'when a command is deprecated' do
      let(:arguments) { ['publish'] }
      it 'should print a helpful message' do
        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          expect(run).to eq(1)

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to match(/bind <local|github>/)

        ensure
          $stdout = real_stdout
        end
      end
    end

    context 'when run raises' do
      context 'a KeyError' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise KeyError.new 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

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
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise Configuration::CredentialKeyError.new 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

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
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise CliError::InvalidArguments.new
        end

        let(:arguments) { ['bind', 'local'] }

        it 'shows the command usage' do
          expect(logger).to receive(:log).with(duck_type(:to_s))
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end

      context 'any other error' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

        it 'logs the error message' do
          expect(logger).to receive(:error).with(/I broke/)
          run
        end

        it 'should return 1' do
          expect(run).to eq 1
        end
      end
    end

    describe 'flags' do
      context 'when the input flag is --version' do
        it 'should log the gemspec version' do
          gem_root = File.expand_path('../../../../', __FILE__)
          expect(logger).to receive(:log).with("bookbinder #{Gem::Specification::load(File.join gem_root, "bookbinder.gemspec").version}")
          expect(cli.run ['--version']).to eq(0)
        end

        it 'the flag is added to the usage list' do
          expect(logger).to receive(:log).with(/--#{Regexp.escape('version')}/)
          cli.run []
        end
      end

      context 'when the input flag is --help' do
        it 'logs the command usages including --help' do
          expect(logger).to receive(:log).with(/--#{Regexp.escape('help')}/)
          expect(cli.run ['--help']).to eq(0)
        end
      end

      context 'when a flag that is not recognized is supplied' do
        let(:arguments) { ['--foo'] }

        it 'should print a helpful message' do
          begin
            real_stdout = $stdout
            $stdout = StringIO.new

            run

            $stdout.rewind
            collected_output = $stdout.read

            expect(collected_output).to match(/Unrecognized flag '--foo'/)
          ensure
            $stdout = real_stdout
          end
        end
      end
    end
  end
end
