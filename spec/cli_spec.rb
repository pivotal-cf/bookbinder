require 'spec_helper'

describe Cli do

  let(:cli) { Cli.new }

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

  context 'when config.yml is missing a required key' do
    before do
      File.stub(:read)
      YAML.stub(:load).and_return({foo: 'bar'})
    end

    let(:arguments) { ['publish', 'local'] }

    it 'should print a helpful message' do
      BookbinderLogger.should_receive(:log).with(/key not found:.*in config\.yml/)
      run
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

  shared_examples_for 'a cli that dispatches commands' do
    let(:arguments) { [command_string] + extra_args}
    let(:extra_args) { ['arg1', 'arg2'] }
    let(:fake_command) { double }

    before {  command_class.stub(:new) { fake_command } }

    it 'should run the publish command' do
      fake_command.should_receive(:run).with(['arg1', 'arg2'])
      run
    end

    it 'returns whatever the publish command returned' do
      fake_command.should_receive(:run).and_return(42)
      expect(run).to eq(42)
    end

    context 'when the command raises an exception' do
      before { fake_command.should_receive(:run).and_raise('Aaaaaah!!') }

      it 'should return a non-zero exit status' do
        expect(run).to eq(1)
      end

      it "should log a message with the exception's message" do
        BookbinderLogger.should_receive(:log).with(/Aaaaaah!!/)
        run
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

  describe Cli::RunPublishCI do

    let(:fake_publish) { double }
    let(:fake_push_local_to_staging) { double }
    let(:fake_build_and_push_tarball) { double }

    before do
      ENV.stub(:[])
      ENV.stub(:[]).with('BUILD_NUMBER').and_return('42424242')
      Cli::Publish.stub(:new) { fake_publish }
      Cli::PushLocalToStaging.stub(:new) { fake_push_local_to_staging }
      Cli::BuildAndPushTarball.stub(:new) { fake_build_and_push_tarball }
    end

    it 'runs three commands and returns 0 if all three do so' do
      fake_publish.should_receive(:run).with(['github']).and_return(0)
      fake_push_local_to_staging.should_receive(:run).with([]).and_return(0)
      fake_build_and_push_tarball.should_receive(:run).with([]).and_return(0)
      result = Cli::RunPublishCI.new.run []
      expect(result).to eq(0)
    end

    it 'does not execute PushLocalToStaging if Publish fails' do
      fake_publish.should_receive(:run).with(['github']).and_return(1)
      fake_push_local_to_staging.should_not_receive(:run)
      fake_build_and_push_tarball.should_not_receive(:run)
      result = Cli::RunPublishCI.new.run []
      expect(result).to eq(1)
    end

    it 'does not execute BuildAndPushTarball if PushLocalToStaging fails' do
      fake_publish.should_receive(:run).with(['github']).and_return(0)
      fake_push_local_to_staging.should_receive(:run).with([]).and_return(1)
      fake_build_and_push_tarball.should_not_receive(:run)
      result = Cli::RunPublishCI.new.run []
      expect(result).to eq(1)
    end
  end
end