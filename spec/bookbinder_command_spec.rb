require 'spec_helper'

describe Cli::BookbinderCommand do
  class FakeBookbinderCommand < Cli::BookbinderCommand
  end

  let(:command) { FakeBookbinderCommand.new }

  describe '#run' do
    it 'delegates to child_run' do
      args = [1, 'a']
      expect(command).to receive(:child_run).with(*args)

      command.run(*args)
    end

    context 'when child_run raises' do
      context 'a Cli::CredentialKeyError' do
        before do
          command.stub(:child_run).and_raise Cli::CredentialKeyError.new 'I broke'
        end

        it 'should log the error with the credentials file name' do
          BookbinderLogger.should_receive(:log).with(/I broke.*in credentials.yml/)
          command.run
        end

        it 'should return 1' do
          expect(command.run).to eq 1
        end
      end

      context 'a KeyError' do
        before do
          command.stub(:child_run).and_raise KeyError.new 'I broke'
        end

        it 'should log the error with the config file name' do
          BookbinderLogger.should_receive(:log).with(/I broke.*in config.yml/)
          command.run
        end

        it 'should return 1' do
          expect(command.run).to eq 1
        end
      end

      context 'any other error' do
        before do
          command.stub(:child_run).and_raise 'I broke'
        end

        it 'should log the error' do
          BookbinderLogger.should_receive(:log).with(/I broke/)
          command.run
        end

        it 'should return 1' do
          expect(command.run).to eq 1
        end
      end
    end
  end

  describe '#config' do
    include_context 'tmp_dirs'

    let(:config_path) { './config.yml' }

    describe '#config' do
      before do
        stub_github_for('fantastic/creds-repo')
      end

      around_with_fixture_repo do |example|
        example.run
      end

      it 'exposes config.yml' do
        expect(command.config['book_repo']).to eq('fantastic/fixture-book-title')
      end

      context 'if config.yml is empty' do
        it 'raises' do
          File.open(config_path, 'w') { |f| f.write('') }

          expect {
            command.config
          }.to raise_error('config.yml is empty')
        end
      end
    end
  end
end
