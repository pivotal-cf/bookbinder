module SpecHelperMethods
  def stub_github_for(git_client, repo_name, some_ref = 'master')
    zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_ref}.tar.gz"
    allow(git_client).to receive(:archive_link).with(repo_name, ref: some_ref).and_return(zipped_repo_url)

    zipped_repo = RepoFixture.tarball repo_name.split('/').last, some_ref
    stub_request(:get, zipped_repo_url).to_return(
        :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
    )

    stub_refs_for_repo repo_name, [some_ref]
  end

  def stub_refs_for_repo(name, refs)
    all_refs_url = "https://api.github.com/repos/#{name}/git/refs"

    ref_response = refs.map do |ref|
      sha = SecureRandom.hex(20)
      {
          "ref" => "refs/heads/#{ref}",
          "url" => "https://api.github.com/repos/#{name}/git/refs/heads/#{ref}",
          "object" => {
              "sha" => sha,
              "type" => "commit",
              "url" => "https://api.github.com/repos/#{name}/git/commits/#{sha}"
          }
      }
    end

    stub_request(:get, all_refs_url).to_return(status: 200, body: ref_response.to_json, headers: {'Content-Type' => 'application/json; charset=utf-8'})
  end

  def mock_github_for(git_client, repo_name, some_ref='master')
    zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_ref}.tar.gz"
    expect(git_client).to receive(:archive_link).with(repo_name, ref: some_ref)
                          .once
                          .and_return(zipped_repo_url)

    zipped_repo = RepoFixture.tarball repo_name.split('/').last, some_ref
    stub_request(:get, zipped_repo_url).to_return(
        :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
    )

    stub_refs_for_repo repo_name, [some_ref]
  end


  def stub_github_commits(name: nil, sha: 'master')
    stub_request(:get, "https://api.github.com/repos/#{name}/git/trees/#{sha}?recursive=true").
        to_return(:status => 200, :body => "{\"tree\":[{\"path\":\"abc\",\"sha\":\"123\"}]}", headers: {'Content-type' => 'application/json'})
    stub_request(:get, "https://api.github.com/repos/#{name}/commits?path=abc&sha=#{sha}").
        to_return(:status => 200, :body => "[{\"commit\":{\"author\":{\"date\":\"12-12-12\"}}}]", headers: {'Content-type' => 'application/json'})
  end
end