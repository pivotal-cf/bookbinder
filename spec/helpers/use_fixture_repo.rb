require_relative '../fixtures/repo_fixture'

def use_fixture_repo
  around do |spec|
    temp_library = tmp_subdir 'repositories'
    FileUtils.cp_r File.join(Bookbinder::RepoFixture.repos_dir, '.'), temp_library
    FileUtils.cd(File.join(temp_library, 'book')) do
      spec.run
    end
  end
end
