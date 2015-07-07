require_relative '../../../../lib/bookbinder/deploy/artifact'

module Bookbinder
  module Deploy
    describe Artifact do
      let(:namespace) { 'spock' }
      let(:build_number) { '9' }
      let(:extension) { 'vlcn' }
      let(:path) { '/home/sweet/planet' }

      let(:artifact) { described_class.new(namespace, build_number, extension, path) }

      describe '#filename' do
        it 'has namespace, buildnumber, and extension' do
          expect(artifact.filename).to eq('spock-9.vlcn')
        end
      end

      describe '#full_path' do
        it 'has the path and filename' do
          expect(artifact.full_path).to eq('/home/sweet/planet/spock-9.vlcn')
        end

        context 'when path is not specified' do
          let(:artifact) { described_class.new(namespace, build_number, extension) }

          it 'uses the current directory for path' do
            expect(artifact.full_path).to eq('./spock-9.vlcn')
          end
        end
      end
    end
  end
end
