require 'spec_helper'

describe Cli do
  include_context 'tmp_dirs'

  let(:cli) { Cli.new }
  let(:cred_repo) { 'fantastic/creds-repo' }

  around_with_fixture_repo &:run

  before { stub_github_for cred_repo } # TODO rip off bandaid

  shared_examples_for 'a cli that dispatches commands' do
    let(:arguments) { [command_string] + extra_args }
    let(:extra_args) { ['arg1', 'arg2'] }
    let(:fake_command) { double }

    def run
      cli.run arguments
    end

    before { command_class.stub(:new) { fake_command } }

    it 'should run the publish command' do
      fake_command.should_receive(:run).with(['arg1', 'arg2'])
      run
    end

    it 'returns whatever the publish command returned' do
      fake_command.should_receive(:run).and_return(42)
      expect(run).to eq(42)
    end
  end

  describe '#run' do
    def run
      cli.run arguments
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

    context 'when config.yml is missing' do
      before { File.stub(:read).and_raise(Errno::ENOENT) }

      let(:arguments) { ['publish', 'local'] }

      it 'should print a helpful message' do
        BookbinderLogger.should_receive(:log).with(/No such file or directory/)
        run
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
      let(:configuration) { {cool: 'config', without: 'credentials'} }
      before { File.write('./config.yml', configuration.to_yaml) }

      it 'passes configuration to the given command' do
        expect(Cli::Publish).to receive(:new).with(configuration)
        cli.run ['publish', 'local']
      end

      context 'when credentals repo is defined in the config' do
        let(:configuration) { {'cred_repo' => cred_repo, 'arbitrary' => 'values'} }
        let(:credentials) do
          {
            'secure_site'=>{'pass'=>'secret', 'handle'=>'agent'}
          }
        end

        it "includes the fetched credentials in the Command's configuration" do
          expect(Cli::Publish).to receive(:new).with configuration.merge(credentials)
          cli.run ['publish', 'local']
        end
      end
    end
  end

  context 'when given the "publish" command' do
    let(:command_string) { 'publish' }
    let(:command_class) { Cli::Publish }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "tag" command' do
    let(:command_string) { 'tag' }
    let(:command_class) { Cli::Tag }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "build_and_push_tarball" command' do
    let(:command_string) { 'build_and_push_tarball' }
    let(:command_class) { Cli::BuildAndPushTarball }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "doc_repos_updated" command' do
    let(:command_string) { 'doc_repos_updated' }
    let(:command_class) { Cli::DocReposUpdated }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "push_local_to_staging" command' do
    let(:command_string) { 'push_local_to_staging' }
    let(:command_class) { Cli::PushLocalToStaging }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "push_to_prod" command' do
    let(:command_string) { 'push_to_prod' }
    let(:command_class) { Cli::PushToProd }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "run_publish_ci" command' do
    let(:command_string) { 'run_publish_ci' }
    let(:command_class) { Cli::RunPublishCI }
    it_should_behave_like 'a cli that dispatches commands'
  end

  context 'when given the "update_local_doc_repos" command' do
    let(:command_string) { 'update_local_doc_repos' }
    let(:command_class) { Cli::UpdateLocalDocRepos }
    it_should_behave_like 'a cli that dispatches commands'
  end
end
