require_relative '../../../lib/bookbinder/cli'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe Cli do
    let(:cli) { Cli.new }

    def run
      cli.run arguments
    end

    context 'when config fails validation' do
      use_fixture_repo('invalid_config')
      let(:arguments) { ['bind', 'local'] }
      subject { capture_stdout { run } }
      it { should have_output('required keys').in_red }
    end

    context 'when no arguments are supplied' do
      let(:arguments) { [] }
      subject { capture_stdout { run } }
      it { should have_output('usage').in_bold_white }
    end

    context 'when a command that is not recognized is supplied' do
      let(:arguments) { ['foo'] }
      subject { capture_stdout { run } }
      it { should have_output("unrecognized command 'foo'").in_red }
    end

    context 'when a command is deprecated' do
      let(:arguments) { ['publish'] }
      subject { capture_stdout { run } }
      it { should have_output(Regexp.escape('bind <local|github>')).in_yellow }
    end

    context 'when run raises' do
      context 'a KeyError' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise KeyError.new 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

        it 'logs the error with the config file name' do
          expect(capture_stdout { run }).
            to have_output(/I broke.*your configuration/).
            in_red
        end

        it 'should return 1' do
          expect(swallow_stdout { run }).to eq 1
        end
      end

      context 'a Configuration::CredentialKeyError' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise Configuration::CredentialKeyError.new 'I broke'
        end

        let(:arguments) { ['bind', 'local'] }

        it 'logs the error with the credentials file name' do
          expect(capture_stdout { run }).
            to have_output(/I broke.*in credentials\.yml/).
            in_red
        end

        it 'should return 1' do
          expect(swallow_stdout { run }).to eq 1
        end
      end

      context 'for InvalidArguments' do
        before do
          allow_any_instance_of(Commands::Bind).to receive(:run).and_raise CliError::InvalidArguments.new
        end

        let(:arguments) { ['bind', 'local'] }

        it 'shows the command usage' do
          expect(capture_stdout { run }).
            to have_output(Regexp.escape('bind <local|github>'))
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
          expect(capture_stdout { run }).to have_output('i broke').in_red
        end

        it 'should return 1' do
          expect(swallow_stdout { run }).to eq 1
        end
      end
    end

    describe 'flags' do
      context 'when the input flag is --version' do
        it 'should log the gemspec version' do
          gem_root = File.expand_path('../../../../', __FILE__)
          expect(capture_stdout { cli.run(['--version']) }).
            to have_output(
              "bookbinder #{Gem::Specification::load(File.join gem_root, "bookbinder.gemspec").version}"
            )
        end

        it "returns 0" do
          expect(swallow_stdout { cli.run(['--version']) }).to eq(0)
        end
      end

      context 'when the input flag is --help' do
        it 'logs the command usages including --help' do
          expect(capture_stdout { cli.run(['--help']) }).
            to have_output('--help')
        end

        it "returns 0" do
          expect(swallow_stdout { cli.run ['--help'] }).to eq(0)
        end
      end

      context 'when a flag that is not recognized is supplied' do
        let(:arguments) { ['--foo'] }
        subject { capture_stdout { run } }
        it { should have_output("Unrecognized flag '--foo'").in_red }
      end
    end

    def capture_stdout(&block)
      real_stdout = $stdout
      $stdout = StringIO.new
      block.call
      $stdout.rewind
      $stdout.read
    ensure
      $stdout = real_stdout
    end

    def swallow_stdout(&block)
      real_stdout = $stdout
      $stdout = StringIO.new
      block.call
    ensure
      $stdout = real_stdout
    end

    matcher(:have_output) do |regexp|
      raise ArgumentError, "Must provide a regexp" if regexp.nil?
      chain(:in_red) do
        @color = Regexp.escape("\e[31m")
      end
      chain(:in_yellow) do
        @color = Regexp.escape("\e[33m")
      end
      chain(:in_bold_white) do
        @color = Regexp.escape("\e[1;39;49m")
      end
      match do |output|
        output.match(/#{@color}.*#{regexp}/im)
      end
      failure_message do |output|
        "Expected #{"colorized " if @color}regexp '#{regexp}' to be in output:\n#{output}"
      end
    end
  end
end
