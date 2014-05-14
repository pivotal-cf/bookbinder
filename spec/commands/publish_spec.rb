require 'spec_helper'

module Bookbinder
  describe Cli::Publish do
    include_context 'tmp_dirs'

    around_with_fixture_repo do |spec|
      spec.run
    end

    let(:sections) do
      [
          {'repository' => {'name' => 'fantastic/dogs-repo', 'ref' => 'dog-sha'}, 'directory' => 'dogs', 'subnav_template' => 'dogs'},
          {'repository' => {'name' => 'fantastic/my-docs-repo', 'ref' => 'my-docs-sha'}, 'directory' => 'foods/sweet', 'subnav_template' => 'fruits'},
          {'repository' => {'name' => 'fantastic/my-other-docs-repo', 'ref' => 'my-other-sha'}, 'directory' => 'foods/savory', 'subnav_template' => 'vegetables'}
      ]
    end

    let(:config_hash) do
      {'sections' => sections, 'book_repo' => book, 'pdf_index' => [], 'public_host' => 'example.com'}
    end

    let(:config) { Configuration.new(logger, config_hash) }

    let(:book) { 'fantastic/book' }
    let(:logger) { NilLogger.new }
    let(:publish_command) { Cli::Publish.new(logger, config) }
    let(:git_client) { GitClient.new(logger) }

    before do
      allow(ProgressBar).to receive(:create).and_return(double(increment: nil))
      sections.each { |s| stub_github_commits(name: s['repository']['name']) }
      Spider.any_instance.stub(:generate_sitemap)
    end

    context 'local' do
      around do |spec|
        WebMock.disable_net_connect!(:allow_localhost => true)
        spec.run
        WebMock.disable_net_connect!
      end

      let(:dogs_index) { File.join('final_app', 'public', 'dogs', 'index.html') }

      def response_for(page)
        publish_command.run ['local']

        response = nil
        ServerDirector.new(logger, directory: 'final_app').use_server do |port|
          uri = URI "http://localhost:#{port}/#{page}"
          req = Net::HTTP::Get.new(uri.path)
          response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
        end
        response
      end

      it 'runs idempotently' do
        silence_io_streams do
          publish_command.run ['local'] # Run Once

          expect do
            publish_command.run ['local'] # Run twice
          end.not_to change { File.exist? dogs_index }.from(true).to(false)
        end
      end

      it 'creates some static HTML' do
        publish_command.run ['local']

        index_html = File.read dogs_index
        index_html.should include 'Woof'
      end

      it 'respects a redirects file' do
        redirect_rules = "r301 '/index.html', '/dogs/index.html'"

        expect { File.write('redirects.rb', redirect_rules) }.to change {
          response_for('index.html')
        }.from(Net::HTTPSuccess).to(Net::HTTPMovedPermanently)
      end

      context 'when provided a layout repo' do
        let(:config_hash) do
          {'sections' => sections, 'book_repo' => book, 'pdf_index' => [], 'public_host' => 'example.com', 'layout_repo' => 'such-org/layout-repo'}
        end

        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)
          expect(Publisher).to receive(:new).and_return fake_publisher

          expect(fake_publisher).to receive(:publish) do |args|
            expect(args[:master_middleman_dir]).to match('layout-repo')
          end

          publish_command.run ['local']
        end
      end
    end

    context 'github' do

      let(:zipped_repo_url) { "https://github.com/#{book}/archive/master.tar.gz" }

      before do
        allow(git_client).to receive(:archive_link) { |repo, ref| raise "Stub #{repo} for #{ref}!" }
        stub_github_for git_client, 'fantastic/dogs-repo', 'dog-sha'
        stub_github_for git_client, 'fantastic/my-docs-repo', 'my-docs-sha'
        stub_github_for git_client, 'fantastic/my-other-docs-repo', 'my-other-sha'
        allow(GitClient).to receive(:new).and_return(git_client)
      end

      it 'creates some static HTML' do
        sections.each { |s| stub_github_commits(name: s['repository']['name'], sha: s['repository']['ref']) }

        publish_command.run ['github']

        index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        index_html.should include 'This is a Markdown Page'
      end


      context 'when a tag is provided' do
        let(:desired_tag) { 'foo-1.7.12' }
        let(:cli_args) { ['github', desired_tag] }
        let(:zipped_repo_url) { "https://github.com/#{book}/archive/#{desired_tag}.tar.gz" }

        before do
          sections.each { |s| stub_github_commits(name: s['repository']['name'], sha: desired_tag) }

          stub_github_for git_client, 'fantastic/dogs-repo', desired_tag
          stub_github_for git_client, 'fantastic/my-docs-repo', desired_tag
          stub_github_for git_client, 'fantastic/my-other-docs-repo', desired_tag

          zipped_repo = RepoFixture.tarball 'book', desired_tag
          stub_request(:get, zipped_repo_url).to_return(:body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'})
          stub_refs_for_repo(book, [desired_tag])
        end

        it 'gets the book at that tag' do
          mock_github_for git_client, book, desired_tag
          publish_command.run cli_args
        end

        context 'the old config.yml lists fewer repos than the new config.yml' do
          let(:early_section) { 'fantastic/dogs-repo' }
          let(:another_early_section) { 'fantastic/my-docs-repo' }
          let(:later_section) { 'fantastic/my-other-docs-repo' }

          let(:zipped_book) do
            RepoFixture.tarball('book', desired_tag) do |dir|
              config_file = File.join(dir, 'config.yml')
              config = YAML.load(File.read(config_file))
              config['sections'].pop
              File.write(config_file, config.to_yaml)
            end
          end

          before do
            stub_github_for git_client, book, desired_tag, zipped_book
          end

          it 'calls for the old sections, but not the new sections' do
            mock_github_for git_client, early_section, desired_tag
            mock_github_for git_client, another_early_section, desired_tag
            expect(git_client).not_to receive(:archive_link).with(later_section, anything)

            publish_command.run cli_args
          end
        end
      end

      context 'when provided a layout repo' do
        let(:config_hash) do
          {'sections' => sections, 'book_repo' => book, 'pdf_index' => [], 'public_host' => 'example.com', 'layout_repo' => 'such-org/layout-repo'}
        end

        before do
          mock_github_for(git_client, 'such-org/layout-repo')
          allow(GitClient).to receive(:new).and_return(git_client)
        end

        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)
          expect(Publisher).to receive(:new).and_return fake_publisher

          expect(fake_publisher).to receive(:publish) do |args|
            expect(args[:master_middleman_dir]).to match('layout-repo')
          end

          publish_command.run ['github']
        end
      end

      context 'when multiple versions are provided' do
        let(:book_without_third_section) do
          RepoFixture.tarball('book', 'v1') do |dir|
            config_file = File.join(dir, 'config.yml')
            config = YAML.load(File.read(config_file))
            config['sections'].pop
            File.write(config_file, config.to_yaml)
          end
        end

        before do
          sections.each do |s|
            stub_github_commits(name: s['repository']['name'], sha: s['repository']['ref'])
          end

          stub_github_for(git_client, book, 'v1', book_without_third_section)
          stub_github_for(git_client, 'fantastic/dogs-repo', 'v1')
          stub_github_commits(name: 'fantastic/dogs-repo', sha: 'v1')
          stub_github_for(git_client, 'fantastic/my-docs-repo', 'v1')
          stub_github_commits(name: 'fantastic/my-docs-repo', sha: 'v1')

          stub_github_for(git_client, book, 'v2')
          stub_github_for(git_client, 'fantastic/dogs-repo', 'v2')
          stub_github_commits(name: 'fantastic/dogs-repo', sha: 'v2')
          stub_github_for(git_client, 'fantastic/my-docs-repo', 'v2')
          stub_github_commits(name: 'fantastic/my-docs-repo', sha: 'v2')
          stub_github_for(git_client, 'fantastic/my-other-docs-repo', 'v2')
          stub_github_commits(name: 'fantastic/my-other-docs-repo', sha: 'v2')
        end

        let(:versions) { %w(v1 v2) }

        let(:config_hash) do
          {
              'versions' => versions,
              'sections' => sections,
              'book_repo' => book,
              'pdf_index' => [],
              'public_host' => 'example.com'
          }
        end

        it 'publishes previous versions of the book down paths named for the version tag' do
          publish_command.run ['github']


          index_html = File.read File.join('final_app', 'public', 'dogs', 'index.html')
          expect(index_html).to include 'images/breeds.png'

          index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'

          index_html = File.read File.join('final_app', 'public', 'foods', 'savory', 'index.html')
          expect(index_html).to include 'This is another Markdown Page'


          v1_dir = File.join('final_app', 'public', 'v1')
          index_html = File.read File.join(v1_dir, 'dogs', 'index.html')
          expect(index_html).to include 'images/breeds.png'

          index_html = File.read File.join(v1_dir, 'foods', 'sweet', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'

          expect(File.exist? File.join(v1_dir, 'foods', 'savory', 'index.html')).to be_false


          v2_dir = File.join('final_app', 'public', 'v2')
          index_html = File.read File.join(v2_dir, 'dogs', 'index.html')
          expect(index_html).to include 'images/breeds.png'

          index_html = File.read File.join(v2_dir, 'foods', 'sweet', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'

          index_html = File.read File.join(v2_dir, 'foods', 'savory', 'index.html')
          expect(index_html).to include 'This is another Markdown Page'

        end
      end
    end

    describe 'invalid arguments' do
      it 'raises Cli::InvalidArguments' do
        expect {
          publish_command.run ['blah', 'blah', 'whatever']
        }.to raise_error(Cli::InvalidArguments)

        expect {
          publish_command.run []
        }.to raise_error(Cli::InvalidArguments)
      end
    end

    describe 'publication arguments' do
      let(:cache) { double('GitModCache') }
      let(:fake_publisher) { double('publisher') }

      let(:all_these_arguments_and_such) do
        {sections: sections,
         output_dir: anything,
         master_middleman_dir: anything,
         final_app_dir: anything,
         pdf: nil,
         verbose: false,
         pdf_index: [],
         local_repo_dir: anything,
         host_for_sitemap: 'example.com',
         template_variables: {},
         file_cache: cache,
         book_repo: 'fantastic/book',
         versions: []}
      end

      before do
        allow(GitModCache).to receive(:new).and_return(cache)
        expect(Publisher).to receive(:new).and_return fake_publisher
      end

      it 'are appropriate' do
        expect(fake_publisher).to receive(:publish).with all_these_arguments_and_such
        publish_command.run ['local']
      end
    end
  end
end