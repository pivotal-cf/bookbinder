require 'spec_helper'

describe GitModCache do
  include_context 'tmp_dirs'
  around_with_fixture_repo &:run

  subject(:cache) { GitModCache.new cachefile }

  let(:cachefile) { 'cache' }

  let(:initial_contents) do
    {
        shas_by_file: {'initial-path' => 'initial-sha'},
        dates_by_sha: {'initial-sha' => 'initial-date'}
    }
  end

  before { File.write(cachefile, initial_contents.to_yaml) }

  describe '#update_from' do
    let(:repo_1) do
      double(:repository, shas_by_file: {
          'path/to/file1' => 'file-1-sha',
          'path/to/file2' => 'file-2-sha'
      }, directory: 'fake-org/fake-repo-1')
    end

    let(:repo_2) do
      double(:repository, shas_by_file: {
          'path/to/file3' => 'file-3-sha',
          'path/to/file4' => 'file-4-sha'
      }, directory: 'fake-org/fake-repo-2')
    end

    context 'when the cache file exists' do
      it 'writes new information provided by the repo to the cache file' do
        expected_except_1 = initial_contents[:dates_by_sha]

        expect(repo_1).to receive(:dates_by_sha).with(
                              {
                                  'path/to/file1' => 'file-1-sha',
                                  'path/to/file2' => 'file-2-sha'
                              },
                              {except: expected_except_1})
                          .and_return(
                              {
                                  'file-1-sha' => 'file-1-date',
                                  'file-2-sha' => 'file-2-date',
                              })

        expected_except_2 = expected_except_1.merge(
            'file-1-sha' => 'file-1-date',
            'file-2-sha' => 'file-2-date'
        )

        expect(repo_2).to receive(:dates_by_sha).with(
                              {
                                  'path/to/file3' => 'file-3-sha',
                                  'path/to/file4' => 'file-4-sha'
                              },
                              {except: expected_except_2})
                          .and_return(
                              'file-3-sha' => 'file-3-date',
                              'file-4-sha' => 'file-4-date'
                          )

        final_contents = {
            shas_by_file: initial_contents[:shas_by_file].merge(
                'fake-org/fake-repo-1/path/to/file1' => 'file-1-sha',
                'fake-org/fake-repo-1/path/to/file2' => 'file-2-sha',

                'fake-org/fake-repo-2/path/to/file3' => 'file-3-sha',
                'fake-org/fake-repo-2/path/to/file4' => 'file-4-sha'
            ),
            dates_by_sha: initial_contents[:dates_by_sha].merge(
                'file-1-sha' => 'file-1-date',
                'file-2-sha' => 'file-2-date',
                'file-3-sha' => 'file-3-date',
                'file-4-sha' => 'file-4-date',
            )
        }

        cache.update_from repo_1
        cache.update_from repo_2

        contents_on_disk = YAML.load_file(cachefile)
        expect(contents_on_disk).to eq final_contents
      end
    end

    context 'when the cache file is absent' do
      before { FileUtils.rm cachefile }

      it 'writes new information provided by the repo to the cache file' do
        expect(repo_1).to receive(:dates_by_sha).with({
                                                          'path/to/file1' => 'file-1-sha',
                                                          'path/to/file2' => 'file-2-sha'
                                                      },
                                                      {except: {}})
                          .and_return(
                              'file-1-sha' => 'file-1-date',
                              'file-2-sha' => 'file-2-date'
                          )
        final_contents = {
            shas_by_file: {
                "#{repo_1.directory}/path/to/file1" => 'file-1-sha',
                "#{repo_1.directory}/path/to/file2" => 'file-2-sha'
            },
            dates_by_sha: {
                'file-1-sha' => 'file-1-date',
                'file-2-sha' => 'file-2-date'
            }
        }

        cache.update_from repo_1

        contents_on_disk = YAML.load_file(cachefile)
        expect(contents_on_disk).to eq final_contents
      end
    end
  end

  describe '#fetch' do
    let(:now) { Time.now }

    before { allow(Time).to receive(:now).and_return(now) }

    context 'when the cache has data' do
      let(:initial_contents) do
        {
            shas_by_file: {
                'path/to/file1' => 'file-1-sha',
                'path/to/file2' => 'file-2-sha'
            },
            dates_by_sha: {
                'file-1-sha' => 'file-1-date',
                'file-2-sha' => 'file-2-date'
            }
        }
      end

      it 'returns the date mapped to the filepaths SHA' do
        expect(cache.fetch('path/to/file1')).to eq 'file-1-date'
        expect(cache.fetch('path/to/file2')).to eq 'file-2-date'
      end
    end

    context 'when the cache is empty' do
      let(:initial_contents) { {} }

      it 'returns the current time' do
        expect(cache.fetch('path/to/file1')).to eq now
      end
    end

    context 'when the file path is not found in the cache' do
      let(:initial_contents) do
        {
            shas_by_file: {'foo/bar' => 'bang'},
            dates_by_sha: {'baz/qux' => 'boo'}
        }
      end

      it 'returns the current time' do
        expect(cache.fetch(rand.to_s)).to eq now
      end
    end
  end
end
