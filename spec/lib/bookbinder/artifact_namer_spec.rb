require_relative '../../../lib/bookbinder/artifact_namer'

module Bookbinder
  describe ArtifactNamer do
    let(:namespace) { 'spock' }
    let(:build_number) { '9' }
    let(:extension) { 'vlcn' }
    let(:path) { '/home/sweet/planet' }

    let(:namer) { described_class.new(namespace, build_number, extension, path) }

    describe '#filename' do
      it 'has namespace, buildnumber, and extension' do
        expect(namer.filename).to eq('spock-9.vlcn')
      end
    end

    describe '#full_path' do
      it 'has the path and filename' do
        expect(namer.full_path).to eq('/home/sweet/planet/spock-9.vlcn')
      end

      context 'when path is not specified' do
        let(:namer) { described_class.new(namespace, build_number, extension) }

        it 'uses the current directory for path' do
          expect(namer.full_path).to eq('./spock-9.vlcn')
        end
      end
    end
  end
end
