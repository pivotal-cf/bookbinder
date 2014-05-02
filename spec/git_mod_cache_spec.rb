require 'spec_helper'

describe GitModCache do
  include_context 'tmp_dirs'
  around_with_fixture_repo &:run

  subject(:cache) { GitModCache.new cachefile }

  let(:cachefile) { 'cache' }
  let(:first_path) { 'path/to/file1' }
  let(:second_path) { 'path/to/file2' }
  let(:first_sha) { '--------------' }
  let(:second_sha) { '00000000000' }
  let(:earliest) { 10 }
  let(:latest) { 30000 }
  let(:shas_by_file) { { first_path => first_sha, second_path => second_sha } }
  let(:dates_by_sha) { { first_sha => earliest, second_sha => latest } }

  before { File.write(cachefile, initial_contents.to_yaml) }


  describe '#update' do
    let(:initial_contents) do
      {shas_by_file: {'path' => 'sha'}, dates_by_sha: {'sha' => '4582346'}}
    end
    let(:repo) do
      double(:repository, shas_by_file: shas_by_file)
    end

    context 'when the cache file exists' do
      it 'writes new information provided by the repo to the cache file' do
        expect(repo).to receive(:dates_by_sha).with({first_path => first_sha, second_path => second_sha}, {except: initial_contents[:dates_by_sha]}).and_return(
                            first_sha => earliest, second_sha => latest)

        final_contents = {
            shas_by_file: { first_path => first_sha, second_path => second_sha, 'path' => 'sha' },
            dates_by_sha: { first_sha => earliest, second_sha => latest, 'sha' => '4582346' },
        }

        cache.update_from repo

        contents_on_disk = YAML.load_file(cachefile)
        expect(contents_on_disk).to eq final_contents
      end
    end

    context 'when the cache file is absent' do
      before { FileUtils.rm cachefile }

      it 'writes new information provided by the repo to the cache file' do
        expect(repo).to receive(:dates_by_sha).with({first_path => first_sha, second_path => second_sha}, {:except=>{}}).and_return dates_by_sha

        final_contents = {shas_by_file: shas_by_file, dates_by_sha: dates_by_sha}

        cache.update_from repo

        contents_on_disk = YAML.load_file(cachefile)
        expect(contents_on_disk).to eq final_contents
      end
    end
  end

  describe '#fetch' do
    context 'when the cache has data' do
      let(:initial_contents) { {shas_by_file: shas_by_file, dates_by_sha: dates_by_sha} }

      it 'returns the date mapped to the filepaths SHA' do
        expect(cache.fetch(first_path)).to eq earliest
        expect(cache.fetch(second_path)).to eq latest
      end
    end

    context 'when the cache is empty' do
      let(:initial_contents) { {} }

      it 'returns nil' do
        expect(cache.fetch(first_path)).to eq nil
      end
    end

    context 'when the file path is absent' do
      let(:initial_contents) do
        {shas_by_file: {'foo' => 'bar'}, dates_by_sha: {'baz' => 'qux'}}
      end

      it 'returns nil' do
        expect(cache.fetch(rand.to_s)).to eq nil
      end
    end
  end
end
