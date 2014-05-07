require_relative '../fixtures/repo_fixture'

def around_with_fixture_repo(&block)
  around do |spec|
    temp_library = tmp_subdir 'repositories'
    FileUtils.cp_r File.join(Bookbinder::RepoFixture.repos_dir, '.'), temp_library
    FileUtils.cd(File.join(temp_library, 'book')) do
      block.call(spec)
    end
  end
end