require 'spec_helper'

module Bookbinder
  describe Cli::RunPublishCI do
    let(:fake_publish) { double }
    let(:fake_push_local_to_staging) { double }
    let(:fake_build_and_push_tarball) { double }
    let(:config_hash) { {'book_repo' => 'foo/bar'} }
    let(:config) { Configuration.new(logger, config_hash) }
    let(:logger) { NilLogger.new }
    let(:command) { Cli::RunPublishCI.new(logger, config) }

    before do
      allow(Cli::Publish).to receive(:new).with(logger, config) { fake_publish }
      allow(Cli::PushLocalToStaging).to receive(:new).with(logger, config) { fake_push_local_to_staging }
      allow(Cli::BuildAndPushTarball).to receive(:new).with(logger, config) { fake_build_and_push_tarball }
    end

    context 'when ENV["BUILD_NUMBER"] is set' do
      before do
        ENV.stub(:[])
        ENV.stub(:[]).with('BUILD_NUMBER').and_return('42424242')
      end

      it 'runs three commands and returns 0 if all three do so' do
        expect(fake_publish).to receive(:run).with(['github']).and_return(0)
        expect(fake_push_local_to_staging).to receive(:run).with([]).and_return(0)
        expect(fake_build_and_push_tarball).to receive(:run).with([]).and_return(0)
        result = command.run []
        expect(result).to eq(0)
      end

      it 'does not execute PushLocalToStaging if Publish fails' do
        expect(fake_publish).to receive(:run).with(['github']).and_return(1)
        expect(fake_push_local_to_staging).not_to receive(:run)
        expect(fake_build_and_push_tarball).not_to receive(:run)
        result = command.run []
        expect(result).to eq(1)
      end

      it 'does not execute BuildAndPushTarball if PushLocalToStaging fails' do
        expect(fake_publish).to receive(:run).with(['github']).and_return(0)
        expect(fake_push_local_to_staging).to receive(:run).with([]).and_return(1)
        expect(fake_build_and_push_tarball).not_to receive(:run)
        result = command.run []
        expect(result).to eq(1)
      end

      it 'respects the --verbose flag' do
        publish_command = expect_to_receive_and_return_real_now(Cli::Publish, :new, logger, config)
        expect(publish_command).to receive(:run).with ['github', '--verbose']
        command.run ['--verbose']
      end
    end

    it 'raises MissingBuildNumber if ENV["BUILD_NUMBER"] is not set' do
      expect {
        command.run([])
      }.to raise_error(Cli::BuildAndPushTarball::MissingBuildNumber)
    end
  end
end