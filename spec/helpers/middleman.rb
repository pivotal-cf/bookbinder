module Bookbinder
  module SpecHelperMethods
    def expect_to_receive_and_return_real_now(subject, method, *args)
      real_obj = subject.public_send(method, *args)
      expect(subject).to receive(method).with(*args).and_return(real_obj)
      real_obj
    end

    def generate_middleman_with(index_page)
      dir = tmp_subdir 'master_middleman'
      source_dir = File.join(dir, 'source')
      FileUtils.mkdir source_dir
      FileUtils.cp File.join('spec', 'fixtures', index_page), File.join(source_dir, 'index.html.md.erb')
      dir
    end

    def squelch_middleman_output
      Thor::Shell::Basic.any_instance.stub(:say_status) {}
      Middleman::Logger.any_instance.stub(:add) {}
    end

    def write_markdown_source_file(path_under_source_dir, title, content = nil, breadcrumb_title = nil)
      full_path = File.join(source_dir, path_under_source_dir)
      full_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p full_pathname.dirname
      breadcrumb_code = breadcrumb_title ? "breadcrumb: #{breadcrumb_title}\n" : ''
      final_content = "---\ntitle: #{title}\n#{breadcrumb_code}---\n#{content}"
      File.open(full_path, 'w') { |f| f.write(final_content) }
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

    def stub_github_commits(name: nil, sha: 'master')
      stub_request(:get, "https://api.github.com/repos/#{name}/git/trees/#{sha}?recursive=true").
          to_return(:status => 200, :body => "{\"tree\":[{\"path\":\"abc\",\"sha\":\"123\"}]}", headers: {'Content-type' => 'application/json'})
      stub_request(:get, "https://api.github.com/repos/#{name}/commits?path=abc&sha=#{sha}").
          to_return(:status => 200, :body => "[{\"commit\":{\"author\":{\"date\":\"12-12-12\"}}}]", headers: {'Content-type' => 'application/json'})
    end

    def silence_io_streams
      begin
        orig_stderr = $stderr.clone
        orig_stdout = $stdout.clone
        $stderr.reopen File.new('/dev/null', 'w')
        $stdout.reopen File.new('/dev/null', 'w')
        retval = yield
      rescue Exception => e
        $stdout.reopen orig_stdout
        $stderr.reopen orig_stderr
        raise e
      ensure
        $stdout.reopen orig_stdout
        $stderr.reopen orig_stderr
      end
      retval
    end
  end
end