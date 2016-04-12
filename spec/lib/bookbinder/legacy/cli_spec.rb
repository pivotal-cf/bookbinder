require_relative '../../../../lib/bookbinder/legacy/cli'
require_relative '../../../../lib/bookbinder/ingest/git_accessor'
require_relative '../../../helpers/matchers'
require_relative '../../../helpers/redirection'
require_relative '../../../helpers/use_fixture_repo'

module Bookbinder
  describe Legacy::Cli do
    include Redirection

    let(:cli) { Legacy::Cli.new(Ingest::GitAccessor.new) }

    def run
      cli.run arguments
    end

    context 'when config fails validation' do
      use_fixture_repo('invalid_config')
      let(:arguments) { ['bind', 'local'] }
      subject { capture_stderr { run } }
      it { should have_output('required keys').in_red }
    end

    context 'when run raises' do
      context 'a KeyError' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise KeyError.new 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

        it 'logs the error with the config file name' do
          expect(capture_stderr { run }).
            to have_output(/I broke.*your configuration/).
            in_red
        end

        it 'should return 1' do
          expect(swallow_stderr { run }).to eq 1
        end
      end

      context 'for InvalidArguments' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise CliError::InvalidArguments.new
        end

        let(:arguments) { ['bind', 'local'] }

        it 'shows the command usage' do
          expect(capture_stdout { run }).
            to have_output(Regexp.escape('bind <local|remote>'))
        end

        it 'should return 1' do
          expect(swallow_stdout { run }).to eq 1
        end
      end

      context 'any other error' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

        it 'logs the error message' do
          expect(capture_stderr { run }).to have_output('i broke').in_red
        end

        it 'should return 1' do
          expect(swallow_stderr { run }).to eq 1
        end
      end
    end
  end
end
