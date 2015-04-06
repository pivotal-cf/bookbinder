require_relative '../../../../lib/bookbinder/commands/bind'
require_relative '../../../../lib/bookbinder/config/bind_config_factory'
require_relative '../../../../lib/bookbinder/configuration'
require_relative '../../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../../../lib/bookbinder/dita_preprocessor'
require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/ingest/cloner_factory'
require_relative '../../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../../lib/bookbinder/subnav_formatter'
require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/spec_git_accessor'
require_relative '../../../helpers/use_fixture_repo'

require_relative '../../../../lib/bookbinder/spider'
require_relative '../../../../lib/bookbinder/server_director'
require_relative '../../../../lib/bookbinder/post_production/sitemap_writer'

module Bookbinder
  describe Commands::Bind do

    class FakeArchiveMenuConfig
      def generate(base_config, *)
        base_config
      end
    end

    let(:null_dita_to_html_converter) { double('null dita-to-html converter', convert_to_html_command: []) }
    let(:archive_menu_config) { FakeArchiveMenuConfig.new }

    include SpecHelperMethods

    use_fixture_repo

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

    let(:base_config_hash) do
      {'sections' => sections,
       'book_repo' => book,
       'public_host' => 'example.com',
       'archive_menu' => archive_menu
      }
    end

    def bind_cmd(partial_args = {})
      bind_version_control_system = partial_args.fetch(:version_control_system, SpecGitAccessor)
      bind_logger = partial_args.fetch(:logger, logger)
      bind_config_fetcher = partial_args.fetch(:config_fetcher, config_fetcher)
      Commands::Bind.new(bind_logger,
                         bind_config_fetcher,
                         partial_args.fetch(:bind_config_factory, Config::BindConfigFactory.new(bind_logger, bind_version_control_system, bind_config_fetcher)),
                         partial_args.fetch(:archive_menu_config, archive_menu_config),
                         bind_version_control_system,
                         partial_args.fetch(:file_system_accessor, file_system_accessor),
                         partial_args.fetch(:static_site_generator, middleman_runner),
                         partial_args.fetch(:sitemap_writer, sitemap_writer),
                         partial_args.fetch(:final_app_directory, final_app_dir),
                         partial_args.fetch(:context_dir, File.absolute_path('.')),
                         partial_args.fetch(:dita_preprocessor, dita_preprocessor),
                         partial_args.fetch(:cloner_factory, Ingest::ClonerFactory.new(logger, SpecGitAccessor)),
                         DitaSectionGathererFactory.new(bind_version_control_system, bind_logger),
                         Repositories::SectionRepository.new(logger),
                         partial_args.fetch(:command_creator, command_creator),
                         partial_args.fetch(:sheller, sheller))
    end

    def random_port
      rand(49152..65535)
    end

    let(:book) { 'fantastic/book' }
    let(:command) { bind_cmd }
    let(:command_creator) { double('command creator', convert_to_html_command: 'stubbed command') }
    let(:config) { Configuration.new(logger, config_hash) }
    let(:config_fetcher) { double('config fetcher', fetch_config: config) }
    let(:config_hash) { base_config_hash }
    let(:dita_preprocessor) { DitaPreprocessor.new(null_dita_to_html_converter, static_site_generator_formatter, file_system_accessor) }
    let(:document_parser) { HtmlDocumentManipulator.new }
    let(:file_system_accessor) { LocalFileSystemAccessor.new }
    let(:final_app_dir) { File.absolute_path('final_app') }
    let(:git_client) { GitClient.new }
    let(:logger) { NilLogger.new }
    let(:middleman_runner) { MiddlemanRunner.new(logger, SpecGitAccessor) }
    let(:sheller) { double('sheller', run_command: double('status', success?: true)) }
    let(:sitemap_writer) { PostProduction::SitemapWriter.build(logger, final_app_dir, random_port) }
    let(:static_site_generator_formatter) { DitaHtmlToMiddlemanFormatter.new(file_system_accessor, subnav_formatter, document_parser) }
    let(:subnav_formatter) { SubnavFormatter.new }

    describe "when the DITA processor fails" do
      it "raises an exception" do
        preprocessor = double('preprocessor')
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: Sheller.new(double),
                           command_creator: double('command creator',
                                                   convert_to_html_command: 'false'))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        allow(preprocessor).to receive(:preprocess).and_yield(
          DitaSection.new(nil, nil, nil, 'foo', nil, nil, output_locations)
        )
        expect { command.run(['local']) }.to raise_exception(Commands::Bind::DitaToHtmlLibraryFailure)
      end
    end

    describe 'local' do
      let(:dogs_index) { File.join('final_app', 'public', 'dogs', 'index.html') }

      def response_for(page)
        command.run(['local'])

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
          command.run(['local']) # Run Once
          expect(File.exist? dogs_index).to eq true
          command.run(['local']) # Run twice
          expect(File.exist? dogs_index).to eq true
        end
      end

      it 'creates some static HTML' do
        command.run(['local'])

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
        command.run(['local'])

        index_html = File.read File.join(final_app_dir, 'public', 'foods/sweet', 'index.html')
        expect(index_html).to include 'This is a Markdown Page'
      end

      context 'when provided a layout repo' do
        let(:config_hash) do
          {'sections' => sections, 'book_repo' => book, 'public_host' => 'example.com', 'layout_repo' => 'such-org/layout-repo'}
        end
        
        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)
          expect(Publisher).to receive(:new).and_return fake_publisher
          expect(fake_publisher).to receive(:publish) do |sections, cli_options, output_paths, publish_config, git_accessor|
            expect(output_paths.layout_repo_dir).to match('layout-repo')
          end
          command.run(['local'])
        end
      end

      context 'when code snippets are yielded' do
        let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

        context 'and the code repo is present' do
          it 'can find code example repos locally rather than going to github' do
            expect(SpecGitAccessor).to_not receive(:clone)

            command.run(['local'])
          end
        end
      end
    end

    describe 'github' do
      let(:github_config_hash) do
        base_config_hash.merge({'cred_repo' => 'my-org/my-creds'})
      end

      let(:config_hash) { github_config_hash }

      it 'creates some static HTML' do
        command.run(['github'])

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
          command.run(['github'])
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
          github_config_hash.merge({'layout_repo' => 'such-org/layout-repo'})
        end

        it 'passes the provided repo as master_middleman_dir' do
          fake_publisher = double(:publisher)
          expect(Publisher).to receive(:new).and_return fake_publisher
          expect(fake_publisher).to receive(:publish) do |sections, cli_options, output_paths, publish_config, git_accessor|
            expect(output_paths.layout_repo_dir).to match('layout-repo')
          end
          command.run(['github'])
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

        let(:cli_args) { ['github'] }
        let(:versions) { %w(v1 v2) }
        let(:book) { 'fantastic/book' }
        let(:config_hash) do
          github_config_hash.merge({'versions' => versions})
        end

        it 'binds previous versions of the book down paths named for the version tag' do
          command.run(cli_args)

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
              command.run ['github']
            }.to raise_error(Config::RemoteBindConfiguration::VersionUnsupportedError)
          end
        end
      end
    end

    describe 'validating' do
      context 'when there are invalid arguments' do
        it 'raises Cli::InvalidArguments' do
          expect {
            command.run(['blah', 'blah', 'whatever'])
          }.to raise_error(CliError::InvalidArguments)

          expect {
            command.run([])
          }.to raise_error(CliError::InvalidArguments)
        end
      end
    end

    describe 'generating links' do
      let(:github_config_hash) do
        base_config_hash.merge({'cred_repo' => 'my-org/my-creds'})
      end

      let(:config_hash) { github_config_hash }

      it 'succeeds when all links are functional' do
        exit_code = command.run(['github'])
        expect(exit_code).to eq 0
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
              'cred_repo' => 'my-org/my-creds',
              'public_host' => 'example.com',
              'template_variables' => {'name' => 'Spartacus'}
          }

        config = Configuration.new(logger, config_hash)
        config_fetcher = double('config fetcher', fetch_config: config)

        bind_cmd(config_fetcher: config_fetcher).run(['github'])

        final_app_dir = File.absolute_path('final_app')
        index_html = File.read File.join(final_app_dir, 'public', 'var-repo', 'variable_index.html')
        expect(index_html).to include 'My variable name is Spartacus.'
      end
    end

    describe 'including code snippets' do
      it 'applies the syntax highlighting CSS' do
        section_repo_name = 'org/my-repo-with-code-snippets'
        code_repo = 'cloudfoundry/code-example-repo'

        expect(SpecGitAccessor).
            to receive(:clone).
                   with("git@github.com:#{section_repo_name}",
                        'my-code-snippet-repo',
                        anything).
                   at_least(1).times.
                   and_call_original
        expect(SpecGitAccessor).
            to receive(:clone).
                   with("git@github.com:#{code_repo}",
                        'code-example-repo',
                        anything).
                   at_least(1).times.
                   and_call_original

        sections = [
            {'repository' => {
                'name' => 'org/my-repo-with-code-snippets'},
             'directory' => 'my-code-snippet-repo'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'cred_repo' => 'my-org/my-creds',
            'pdf_index' => [],
            'public_host' => 'example.com',
        }

        config = Configuration.new(logger, config_hash)
        config_fetcher = double('config fetcher', fetch_config: config)

        command = bind_cmd(config_fetcher: config_fetcher)
        silence_io_streams do
          command.run(['github'])
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
    end

    describe 'generating a site-map' do
      context 'when the hostname is not a single string' do
        it 'raises' do
          sections = [
              {'repository' => {'name' => 'org/dogs-repo'}}
          ]

          config_hash = {
              'sections' => sections,
              'book_repo' => book,
              'cred_repo' => 'my-org/my-creds',
              'public_host' => ['host1.runpivotal.com', 'host2.pivotal.io'],
          }

          config = Configuration.new(logger, config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          command = bind_cmd(config_fetcher: config_fetcher)

          expect { command.run(['github']) }.
              to raise_error "Your public host must be a single String."
        end
      end

      context 'when the hostname is a single string' do
        it 'contains the given pages in an XML sitemap' do
          book_dir = File.absolute_path('.')
          middleman_source_dir = File.join(book_dir, 'master_middleman', 'source')
          FileUtils.mkdir_p middleman_source_dir
          FileUtils.cp File.expand_path('../../../../fixtures/dogs_index.html', __FILE__), File.join(middleman_source_dir, 'index.html.md.erb')

          sections = [
              {'repository' => {'name' => 'org/dogs-repo'}}
          ]

          config_hash = {
              'sections' => sections,
              'book_repo' => book,
              'cred_repo' => 'my-org/my-creds',
              'public_host' => 'docs.dogs.com'
          }

          config = Configuration.new(logger, config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          command = bind_cmd(config_fetcher: config_fetcher)
          command.run(['github'])

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
                'repository' => {'name' => 'my-docs-org/my-docs-repo', 'ref' => 'some-sha'},
                'directory' => 'a/b/c'
            }
        ]

        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'cred_repo' => 'my-org/my-creds',
            'public_host' => 'docs.dogs.com'
        }

        config = Configuration.new(logger, config_hash)
        config_fetcher = double('config fetcher', fetch_config: config)

        command = bind_cmd(config_fetcher: config_fetcher)
        command.run(['github'])

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

      before do
        expect(Publisher).to receive(:new).and_return fake_publisher
      end

      it 'pass the appropriate arguments to publish from the config' do
        expect(fake_publisher).to receive(:publish).with anything, expected_cli_options, anything, expected_publish_config
        command.run(['local'])
      end
    end

    describe 'verbose mode' do
      context 'when the verbose flag is not set' do
        it 'suppresses detailed output' do
          sections = [
              {
                  'repository' => {'name' => 'my-docs-org/repo-with-nonexistent-helper-method'},
                  'directory' => nil
              }
          ]
          config_hash = {
              'sections' => sections,
              'book_repo' => book,
              'public_host' => 'docs.dogs.com'
          }

          config = Configuration.new(logger, config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          command = bind_cmd(config_fetcher: config_fetcher)
          begin
            real_stdout = $stdout
            $stdout = StringIO.new

            expect do
              command.run(['github'])
            end.to raise_error

            $stdout.rewind
            collected_output = $stdout.read

            expect(collected_output).to_not match(/error.*build\/index.html/)
            expect(collected_output).to_not match(/undefined local variable or method `function_that_does_not_exist'/)
          ensure
            $stdout = real_stdout
          end
        end
      end

      it 'shows more detailed output when the verbose flag is set' do
        sections = [
            {
                'repository' => {'name' => 'my-docs-org/repo-with-nonexistent-helper-method'},
                'directory' => nil
            }
        ]
        config_hash = {
            'sections' => sections,
            'book_repo' => book,
            'cred_repo' => 'my-org/my-creds',
            'public_host' => 'docs.dogs.com'
        }

        config = Configuration.new(logger, config_hash)
        config_fetcher = double('config fetcher', fetch_config: config)

        command = bind_cmd(config_fetcher: config_fetcher)
        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          expect do
            command.run(['github', '--verbose'])
          end.to raise_error

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to match(/error.*build/)
          expect(collected_output).to match(/undefined local variable or method `function_that_does_not_exist'/)
        ensure
          $stdout = real_stdout
        end
      end
    end

    describe 'creating necessary directories' do
      def create_command
        config = Configuration.new(logger,
                                   'sections' => [],
                                   'book_repo' => book,
                                   'cred_repo' => 'my-org/my-creds',
                                   'public_host' => 'docs.dogs.com')
        config_fetcher = double('config fetcher', fetch_config: config)
        middleman_runner = MiddlemanRunner.new(logger, SpecGitAccessor)
        final_app_dir = File.absolute_path('final_app')
        spider = Spider.new(logger, app_dir: final_app_dir)
        server_director = ServerDirector.new(logger, directory: final_app_dir)

        bind_cmd(config_fetcher: config_fetcher,
                 static_site_generator: middleman_runner,
                 final_app_directory: final_app_dir,
                 spider: spider,
                 server_director: server_director)
      end

      it 'creates the output directory' do
        command = create_command

        output_dir = File.absolute_path('./output')

        expect(File.exists?(output_dir)).to eq false

        command.run(['github'])

        expect(File.exists?(output_dir)).to eq true
      end

      it 'clears the output directory before running' do
        command = create_command

        output_dir = File.absolute_path('./output')
        FileUtils.mkdir_p output_dir
        pre_existing_file = File.join(output_dir, 'happy')
        FileUtils.touch pre_existing_file

        expect(File.exists?(pre_existing_file)).to eq true

        command.run(['github'])

        expect(File.exists?(pre_existing_file)).to eq false
      end

      it 'clears and then copies the template_app skeleton inside final_app' do
        final_app_dir = File.absolute_path('./final_app')
        FileUtils.mkdir_p final_app_dir
        pre_existing_file = File.join(final_app_dir, 'happy')
        FileUtils.touch pre_existing_file

        command = create_command
        command.run(['github'])

        expect(File.exists?(pre_existing_file)).to eq false
        copied_manifest = File.read File.join(final_app_dir, 'app.rb')
        template_manifest = File.read(File.expand_path('../../../../../template_app/app.rb', __FILE__))
        expect(copied_manifest).to eq(template_manifest)
      end
    end
  end
end
