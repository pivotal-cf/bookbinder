require_relative '../../../../lib/bookbinder/commands/run_publish_ci'
require_relative '../../../helpers/middleman'

module Bookbinder
  describe Commands::RunPublishCI do
    include SpecHelperMethods

    let(:fake_publish) { double 'fake_publish' }
    let(:fake_push_local_to_staging) { double 'fake_push_to_staging' }
    let(:fake_build_and_push_tarball) { double 'fake_build_and_push_tarball' }
    let(:command) { Commands::RunPublishCI.new(fake_publish, fake_push_local_to_staging, fake_build_and_push_tarball) }

    context 'when ENV["BUILD_NUMBER"] is set' do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with('BUILD_NUMBER').and_return('42424242')
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
        expect(fake_publish).to receive(:run).with ['github', '--verbose']
        command.run ['--verbose']
      end
    end

    it 'raises MissingBuildNumber if ENV["BUILD_NUMBER"] is not set' do
      expect {
        command.run([])
      }.to raise_error(Commands::BuildAndPushTarball::MissingBuildNumber)
    end
  end
end
