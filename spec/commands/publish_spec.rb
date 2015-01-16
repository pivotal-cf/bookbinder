require 'webmock/rspec'

require_relative '../../lib/bookbinder/commands/publish'

require_relative '../helpers/expectations'
require_relative '../helpers/middleman'
require_relative '../helpers/nil_logger'
require_relative '../helpers/spec_git_accessor'
require_relative '../helpers/tmp_dirs'

module Bookbinder
  describe Commands::Publish do
    include SpecHelperMethods

    include_context 'tmp_dirs'

    around_with_fixture_repo do |spec|
      spec.run
    end

    let(:sections) do
      [
          {'repository' => {
              'name' => 'fantastic/dogs-repo',
              'ref' => 'dog-sha'},
           'directory' => 'dogs',
           'subnav_template' => 'dogs'},
          {'repository' => {
              'name' => 'fantastic/my-docs-repo',
              'ref' => 'some-sha'},
           'directory' => 'foods/sweet',
           'subnav_template' => 'fruits'},
          {'repository' => {
              'name' => 'fantastic/my-other-docs-repo',
              'ref' => 'some-other-sha'},
           'directory' => 'foods/savory',
           'subnav_template' => 'vegetables'}
      ]
    end
    let(:archive_menu) { [] }

    let(:config_hash) do
      {'sections' => sections,
       'book_repo' => book,
       'pdf_index' => [],
       'public_host' => 'example.com',
       'archive_menu' => archive_menu
      }
    end

    let(:config) { Configuration.new(logger, config_hash) }
    let(:book) { 'fantastic/book' }
    let(:logger) { NilLogger.new }
    let(:configuration_fetcher) { double('configuration_fetcher') }
    let(:publish_command) { Commands::Publish.new(logger, configuration_fetcher) }
    let(:git_client) { GitClient.new(logger) }

    before do
      allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
    end

    describe 'local' do
      around do |spec|
        WebMock.disable_net_connect!(:allow_localhost => true)
        spec.run
        WebMock.disable_net_connect!
      end

      let(:dogs_index) { File.join('final_app', 'public', 'dogs', 'index.html') }

      def response_for(page)
        publish_command.run(['local'], SpecGitAccessor)

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
          publish_command.run(['local'], SpecGitAccessor) # Run Once
          expect(File.exist? dogs_index).to eq true
          publish_command.run(['local'], SpecGitAccessor) # Run twice
          expect(File.exist? dogs_index).to eq true
        end
      end

      it 'creates some static HTML' do
        publish_command.run(['local'], SpecGitAccessor)

        index_html = File.read dogs_index
        expect(index_html).to include 'Woof'
      end

      it 'respects a redirects file' do
        redirect_rules = "r301 '/index.html', '/dogs/index.html'"

        expect { File.write('redirects.rb', redirect_rules) }.to change {
          response_for('index.html')
        }.from(Net::HTTPSuccess).to(Net::HTTPMovedPermanently)
      end

      it 'it can find repos locally rather than going to github' do
        final_app_dir = File.absolute_path('final_app')
        publish_command.run(['local'], SpecGitAccessor)

        index_html = File.read File.join(final_app_dir, 'public', 'foods/sweet', 'index.html')
        expect(index_html).to include 'This is a Markdown Page'
      end

      context 'when provided a layout repo' do
        let(:config_hash) do
          {'sections' => sections, 'book_repo' => book, 'pdf_index' => [], 'public_host' => 'example.com', 'layout_repo' => 'such-org/layout-repo'}
        end

        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)

          expect(Publisher).to receive(:new).and_return fake_publisher
          expect(fake_publisher).to receive(:publish) do |cli_options, output_paths, publish_config, git_accessor|
            expect(output_paths[:master_middleman_dir]).to match('layout-repo')
          end
          publish_command.run(['local'], SpecGitAccessor)
        end
      end

      context 'when code snippets are yielded' do
        let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

        context 'and the code repo is present' do
          it 'can find code example repos locally rather than going to github' do
            expect(SpecGitAccessor).to_not receive(:clone)

            publish_command.run(['local'], SpecGitAccessor)
          end
        end

        context 'and the code repo is absent' do
          it 'fails out' do
            sections = [
                    {'repository' => {
                        'name' => 'dev/null',
                        'ref' => 'dog-sha'},
                     'directory' => 'dogs',
                     'subnav_template' => 'dogs'}

            ]

            config_hash = {
                'sections' => sections,
                'book_repo' => book,
                'pdf_index' => [],
                'public_host' => 'example.com',
            }

            config = Configuration.new(logger, config_hash)

            configuration_fetcher = double('configuration_fetcher')
            allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

            publish_command = Commands::Publish.new(logger, configuration_fetcher)

            allow(logger).to receive(:log)
            expect(logger).to receive(:log).with /skipping \(not found\)/
            publish_command.run(['local'], SpecGitAccessor)
            expect(WebMock).not_to have_requested(:get, 'https://api.github.com/repos/fantastic/code-example-repo/tarball/master')
          end
        end
      end
    end

    describe 'github' do
      let(:zipped_repo_url) { "https://github.com/#{book}/archive/master.tar.gz" }

      it 'creates some static HTML' do
        publish_command.run(['github'], SpecGitAccessor)

        index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        expect(index_html).to include 'This is a Markdown Page'
      end

      it 'creates a directory per repo with the generated html from middleman' do
        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{'fantastic/dogs-repo'}",
                                                        "dogs",
                                                        anything).and_call_original

        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{'fantastic/my-docs-repo'}",
                                                        "foods/sweet",
                                                        anything).and_call_original

        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{'fantastic/my-other-docs-repo'}",
                                                        "foods/savory",
                                                        anything).and_call_original

        silence_io_streams do
          publish_command.run(['github'], SpecGitAccessor)
        end

        final_app_dir = File.absolute_path('final_app')

        index_html = File.read File.join(final_app_dir, 'public', 'dogs', 'index.html')
        expect(index_html).to include 'breeds.png'

        other_index_html = File.read File.join(final_app_dir, 'public', 'foods/sweet', 'index.html')
        expect(other_index_html).to include 'This is a Markdown Page'

        third_index_html = File.read File.join(final_app_dir, 'public', 'foods/savory', 'index.html')
        expect(third_index_html).to include 'This is another Markdown Page'
      end

      context 'when provided a layout repo' do
        let(:config_hash) do
          {'sections' => sections,
           'book_repo' => book,
           'pdf_index' => [],
           'public_host' => 'example.com',
           'layout_repo' => 'such-org/layout-repo'}
        end

        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)
          expect(Publisher).to receive(:new).and_return fake_publisher
          expect(fake_publisher).to receive(:publish) do |cli_options, output_paths, publish_config, git_accessor|
            expect(output_paths[:master_middleman_dir]).to match('layout-repo')
          end
          publish_command.run(['github'], SpecGitAccessor)
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

        let(:versions) { %w(v1 v2) }
        let(:cli_args) { ['github'] }
        let(:config_hash) do
          {
              'versions' => versions,
              'sections' => sections,
              'book_repo' => book,
              'pdf_index' => [],
              'public_host' => 'example.com'
          }
        end
        let(:config) { Configuration.new(logger, config_hash) }
        let(:book) { 'fantastic/book' }
        let(:logger) { NilLogger.new }
        let(:publish_commander) { Commands::Publish.new(logger, configuration_fetcher) }
        let(:temp_dir) { Dir.mktmpdir }
        let(:git_accessor_1) { SpecGitAccessor.new('dogs-repo', temp_dir) }
        let(:git_accessor_2) { SpecGitAccessor.new('dogs-repo', temp_dir) }

        it 'publishes previous versions of the book down paths named for the version tag' do
          publish_commander.run(cli_args, SpecGitAccessor)

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
          expect(File.exist? File.join(v1_dir, 'foods', 'savory', 'index.html')).to eq false

          v2_dir = File.join('final_app', 'public', 'v2')
          index_html = File.read File.join(v2_dir, 'dogs', 'index.html')
          expect(index_html).to include 'images/breeds.png'

          index_html = File.read File.join(v2_dir, 'foods', 'sweet', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'

          index_html = File.read File.join(v2_dir, 'foods', 'savory', 'index.html')
          expect(index_html).to include 'This is another Markdown Page'
        end

        context 'when a tag is at an API version that does not have sections' do
          let(:versions) { %w(v1) }
          it 'raises a VersionUnsupportedError' do
            book = double('Book')

            allow(Book).to receive(:from_remote).with(
                               logger: logger,
                               full_name: 'fantastic/book',
                               destination_dir: anything,
                               ref: 'v1',
                               git_accessor: SpecGitAccessor
                           ).and_return(book)
            allow(book).to receive(:directory).and_return('test-directory')
            allow(File).to receive(:read).with(%r{/test-directory/config.yml$}).and_return(
                               "---\nsections: ")

            expect {
              publish_command.run ['github'], SpecGitAccessor
            }.to raise_error(Commands::Publish::VersionUnsupportedError)
          end
        end
      end
    end

    describe 'invalid arguments' do
      it 'raises Cli::InvalidArguments' do
        expect {
          publish_command.run(['blah', 'blah', 'whatever'], SpecGitAccessor)
        }.to raise_error(CliError::InvalidArguments)

        expect {
          publish_command.run([], SpecGitAccessor)
        }.to raise_error(CliError::InvalidArguments)
      end
    end

    describe 'generating links' do
      it 'succeeds when all links are functional' do
        no_broken_links = publish_command.run(['github'], SpecGitAccessor)

        expect(no_broken_links).to eq 0
      end
    end

    describe 'using template variables' do
      it 'includes them into middleman' do
        sections = [
            {'repository' => {
                'name' => 'fantastic/my-variable-repo'},
             'directory' => 'var-repo'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'pdf_index' => [],
            'public_host' => 'example.com',
            'template_variables' => { 'name' => 'Spartacus'}
        }

        config = Configuration.new(logger, config_hash)
        configuration_fetcher = double('configuration_fetcher')
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        publish_command = Commands::Publish.new(logger, configuration_fetcher)
        publish_command.run(['github'], SpecGitAccessor)

        final_app_dir = File.absolute_path('final_app')
        index_html = File.read File.join(final_app_dir, 'public', 'var-repo', 'variable_index.html')
        expect(index_html).to include 'My variable name is Spartacus.'
      end
    end

    describe 'including code snippets' do
      it 'applies the syntax highlighting CSS' do
        section_repo_name = 'org/my-repo-with-code-snippets'
        code_repo = 'cloudfoundry/code-example-repo'

        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{section_repo_name}",
                                                        'my-code-snippet-repo',
                                                        anything).and_call_original
        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{code_repo}",
                                                        'code-example-repo',
                                                        anything).and_call_original

        sections = [
            {'repository' => {
                'name' => 'org/my-repo-with-code-snippets'},
             'directory' => 'my-code-snippet-repo'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'pdf_index' => [],
            'public_host' => 'example.com',
        }

        config = Configuration.new(logger, config_hash)
        configuration_fetcher = double('configuration_fetcher')
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        publish_command = Commands::Publish.new(logger, configuration_fetcher)
        silence_io_streams do
          publish_command.run(['github'], SpecGitAccessor)
        end

        final_app_dir = File.absolute_path('final_app')
        index_html = File.read(File.join(final_app_dir, 'public', 'my-code-snippet-repo', 'code_snippet_index.html'))
        doc = Nokogiri::HTML(index_html)

        ruby_part = 'fib = Enumerator.new do |yielder|'
        yaml_part = 'this_is_yaml'
        typeless_part = 'this = untyped_code'

        ruby_text = doc.css('.highlight.ruby').text
        expect(ruby_text).to include(ruby_part)
        expect(ruby_text).not_to include(yaml_part)
        expect(ruby_text).not_to include(typeless_part)

        yaml_text = doc.css('.highlight.yaml').text
        expect(yaml_text).to include(yaml_part)
        expect(yaml_text).not_to include(ruby_part)
        expect(yaml_text).not_to include(typeless_part)

        typeless_text = doc.css('.highlight.plaintext').text
        expect(typeless_text).to include(typeless_part)
        expect(typeless_text).not_to include(yaml_part)
        expect(typeless_text).not_to include(ruby_part)
      end

      it 'makes only one request per code example repository' do
        Repositories::SectionRepository::SHARED_CACHE.clear
        section_repo_name = 'org/my-repo-with-code-snippets'
        code_repo = 'cloudfoundry/code-example-repo'

        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{section_repo_name}",
                                                        'my-code-snippet-repo',
                                                        anything).and_call_original
        expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{code_repo}",
                                                        'code-example-repo',
                                                        anything).and_call_original

        sections = [
            {'repository' => {
                'name' => 'org/my-repo-with-code-snippets'},
             'directory' => 'my-code-snippet-repo'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'pdf_index' => [],
            'public_host' => 'example.com',
        }

        config = Configuration.new(logger, config_hash)
        configuration_fetcher = double('configuration_fetcher')
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        publish_command = Commands::Publish.new(logger, configuration_fetcher)
        silence_io_streams do
          publish_command.run(['github', '--verbose'], SpecGitAccessor)
        end
      end
    end

    describe 'generates a site-map' do
      context 'when the hostname is not a single string' do
        it 'raises' do
          expect do
            sections = [
                { 'repository' => {'name' => 'org/dogs-repo'} }
            ]

            config_hash = {
                'sections' => sections,
                'book_repo' => book,
                'pdf_index' => [],
                'public_host' => ['host1.runpivotal.com', 'host2.pivotal.io'],
            }

            config = Configuration.new(logger, config_hash)
            configuration_fetcher = double('configuration_fetcher')
            allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

            publish_command = Commands::Publish.new(logger, configuration_fetcher)
            publish_command.run(['github'], SpecGitAccessor)
          end.to raise_error "Your public host must be a single String."
        end
      end

      context 'when the hostname is a single string' do
        around do |spec|
          WebMock.disable_net_connect!(:allow_localhost => true)
          spec.run
          WebMock.disable_net_connect!
        end

        it 'contains the given pages in an XML sitemap' do
          book_dir = File.absolute_path('.')
          middleman_source_dir = File.join(book_dir, 'master_middleman', 'source')
          FileUtils.mkdir_p middleman_source_dir
          FileUtils.cp File.expand_path('../../fixtures/dogs_index.html', __FILE__), File.join(middleman_source_dir, 'index.html.md.erb')

          sections = [
              { 'repository' => {'name' => 'org/dogs-repo'} }
          ]

          config_hash = {
              'sections' => sections,
              'book_repo' => book,
              'public_host' => 'docs.dogs.com'
          }

          config = Configuration.new(logger, config_hash)
          configuration_fetcher = double('configuration_fetcher')
          allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

          publish_command = Commands::Publish.new(logger, configuration_fetcher)
          publish_command.run(['github'], SpecGitAccessor)

          final_app_dir = File.absolute_path('final_app')
          doc = Nokogiri::XML(File.open File.join(final_app_dir, 'public', 'sitemap.xml'))
          expect(doc.css('loc').map &:text).to match_array(%w(
                http://docs.dogs.com/index.html
                http://docs.dogs.com/dogs-repo/index.html
                http://docs.dogs.com/dogs-repo/big_dogs/index.html
                http://docs.dogs.com/dogs-repo/big_dogs/great_danes/index.html
              ))
        end
      end
    end

    describe 'creating subdirectories for a section with a multileveled output directory' do
      it 'creates intermediate directories' do
        sections = [
            {
                'repository' => { 'name' => 'my-docs-org/my-docs-repo', 'ref' => 'some-sha' },
                'directory' => 'a/b/c'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'public_host' => 'docs.dogs.com'
        }

        config = Configuration.new(logger, config_hash)
        configuration_fetcher = double('configuration_fetcher')
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        publish_command = Commands::Publish.new(logger, configuration_fetcher)
        publish_command.run(['github'], SpecGitAccessor)

        final_app_dir = File.absolute_path('final_app')
        index_html = File.read(File.join(final_app_dir, 'public', 'a', 'b', 'c', 'index.html'))
        expect(index_html).to include('This is a Markdown Page')
      end
    end

    describe 'publication arguments' do
      let(:fake_publisher) { double('publisher') }
      let(:git_accessor) { SpecGitAccessor }
      let(:expected_cli_options) do
        {
         verbose: false,
         target_tag: nil
        }
      end
      let(:expected_publish_config) do
        {
         sections: sections,
         host_for_sitemap: 'example.com',
         template_variables: {},
         book_repo: 'fantastic/book',
         archive_menu: archive_menu
        }
      end
      let(:expected_output_paths) do
        {
         output_dir: anything,
         master_middleman_dir: anything,
         final_app_dir: anything,
         local_repo_dir: anything
        }
      end

      before do
        expect(Publisher).to receive(:new).and_return fake_publisher
      end

      it 'pass the appropriate arguments to publish from the config' do
        expect(fake_publisher).to receive(:publish).with expected_cli_options, expected_output_paths, expected_publish_config
        publish_command.run(['local'], SpecGitAccessor)
      end
    end
  end
end
