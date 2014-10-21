require 'spec_helper'

describe Rack::Static do
  let(:index) { 'index.html' }
  let(:app) { Rack::Static.new(double, {urls: urls, index: index}) }
  let(:urls) { ['valid-and-present'] }

  describe '#route_file' do
    context 'when permitted urls include the attempted path' do
      let(:path) { 'valid-and-present' }

      it 'returns true' do
        expect(app.route_file(path)).to eq true
      end
    end

    context 'when permitted urls do not include the attempted path' do
      let(:path) { 'absent' }

      it 'returns false' do
        expect(app.route_file(path)).to eq false
      end
    end

    context 'when an attempted, but invalid path starts with a valid url' do
      let(:path) { 'valid-and-present/absent' }

      it 'returns false' do
        expect(app.route_file(path)).to eq false
      end
    end
  end

  describe '#overwrite_file_path' do
    around do |spec|
      FileUtils.cd(Dir.mktmpdir) { spec.run }
    end

    context 'when the path is an implicit index' do
      before do
        FileUtils.mkdir 'foo'
        FileUtils.touch "foo/#{index}"
      end

      let(:path) { 'foo/' }

      it 'returns true' do
        expect(app.overwrite_file_path(path)).to eq true
      end

      context 'and the index file is absent' do
        let(:path) { 'wrong' }
        it 'returns false' do
          expect(app.overwrite_file_path(path)).to eq false
        end
      end
    end
  end
end
