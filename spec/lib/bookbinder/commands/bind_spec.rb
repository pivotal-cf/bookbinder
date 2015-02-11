require_relative '../../../../lib/bookbinder/commands/bind'
require_relative '../../../helpers/use_fixture_repo'
require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/spec_git_accessor'
require_relative '../../../../lib/bookbinder/configuration'
require_relative '../../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/spider'
require_relative '../../../../lib/bookbinder/dita_html_to_middleman_formatter'

module Bookbinder
  describe Commands::Bind do
    let(:null_dita_processor) { double('null dita processor', process: []) }

    describe 'integration' do
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

      let(:config_hash) do
        {'sections' => sections,
         'book_repo' => book,
         'pdf_index' => [],
         'public_host' => 'example.com',
         'archive_menu' => archive_menu
        }
      end

      let(:config) { Configuration.new(logger, config_hash) }
      let(:config_fetcher) { double('config fetcher', fetch_config: config) }
      let(:book) { 'fantastic/book' }
      let(:logger) { NilLogger.new }
      let(:file_system_accessor) { LocalFileSystemAccessor.new }
      let(:middleman_runner) { MiddlemanRunner.new(logger, SpecGitAccessor) }
      let(:final_app_dir) { File.absolute_path('final_app') }
      let(:spider) { Spider.new(logger, app_dir: final_app_dir) }
      let(:server_director) { ServerDirector.new(logger, directory: final_app_dir) }
      let(:static_site_generator_formatter) { DitaHtmlToMiddlemanFormatter.new(file_system_accessor) }
      let(:publish_command) { Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 SpecGitAccessor,
                                                 file_system_accessor,
                                                 middleman_runner,
                                                 spider,
                                                 final_app_dir,
                                                 server_director,
                                                 File.absolute_path('.'),
                                                 null_dita_processor,
                                                 static_site_generator_formatter) }
      let(:git_client) { GitClient.new }

      describe 'local' do
        let(:dogs_index) { File.join('final_app', 'public', 'dogs', 'index.html') }

        def response_for(page)
          publish_command.run(['local'])

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
            publish_command.run(['local']) # Run Once
            expect(File.exist? dogs_index).to eq true
            publish_command.run(['local']) # Run twice
            expect(File.exist? dogs_index).to eq true
          end
        end

        it 'creates some static HTML' do
          publish_command.run(['local'])

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
          publish_command.run(['local'])

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
            expect(fake_publisher).to receive(:publish) do |sections, cli_options, output_paths, publish_config, git_accessor|
              expect(output_paths[:master_middleman_dir]).to match('layout-repo')
            end
            publish_command.run(['local'])
          end
        end

        context 'when code snippets are yielded' do
          let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

          context 'and the code repo is present' do
            it 'can find code example repos locally rather than going to github' do
              expect(SpecGitAccessor).to_not receive(:clone)

              publish_command.run(['local'])
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
              config_fetcher = double('config fetcher', fetch_config: config)

              publish_command = Commands::Bind.new(logger,
                                                   config_fetcher,
                                                   SpecGitAccessor,
                                                   file_system_accessor,
                                                   middleman_runner,
                                                   spider,
                                                   final_app_dir,
                                                   server_director,
                                                   File.absolute_path('.'),
                                                   null_dita_processor,
                                                   static_site_generator_formatter)
              publish_command.run(['local'])
            end
          end
        end
      end

      describe 'github' do
        it 'creates some static HTML' do
          publish_command.run(['github'])

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
            publish_command.run(['github'])
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
            expect(fake_publisher).to receive(:publish) do |sections, cli_options, output_paths, publish_config, git_accessor|
              expect(output_paths[:master_middleman_dir]).to match('layout-repo')
            end
            publish_command.run(['github'])
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
          let(:publish_command) { Commands::Bind.new(logger,
                                                     config_fetcher,
                                                     SpecGitAccessor,
                                                     file_system_accessor,
                                                     middleman_runner,
                                                     spider,
                                                     final_app_dir,
                                                     server_director,
                                                     File.absolute_path('.'),
                                                     null_dita_processor,
                                                     static_site_generator_formatter) }

          it 'publishes previous versions of the book down paths named for the version tag' do
            publish_command.run(cli_args)

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
                publish_command.run ['github']
              }.to raise_error(Commands::Bind::VersionUnsupportedError)
            end
          end
        end
      end

      describe 'invalid arguments' do
        it 'raises Cli::InvalidArguments' do
          expect {
            publish_command.run(['blah', 'blah', 'whatever'])
          }.to raise_error(CliError::InvalidArguments)

          expect {
            publish_command.run([])
          }.to raise_error(CliError::InvalidArguments)
        end
      end

      describe 'generating links' do
          it 'succeeds when all links are functional' do
          exit_code = publish_command.run(['github'])
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
              'pdf_index' => [],
              'public_host' => 'example.com',
              'template_variables' => { 'name' => 'Spartacus'}
          }

          config = Configuration.new(logger, config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          publish_command = Commands::Bind.new(logger,
                                               config_fetcher,
                                               SpecGitAccessor,
                                               file_system_accessor,
                                               middleman_runner,
                                               spider,
                                               final_app_dir,
                                               server_director,
                                               File.absolute_path('.'),
                                               null_dita_processor,
                                               static_site_generator_formatter)
          publish_command.run(['github'])

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
              'pdf_index' => [],
              'public_host' => 'example.com',
          }

          config = Configuration.new(logger, config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          publish_command = Commands::Bind.new(logger,
                                               config_fetcher,
                                               SpecGitAccessor,
                                               file_system_accessor,
                                               middleman_runner,
                                               spider,
                                               final_app_dir,
                                               server_director,
                                               File.absolute_path('.'),
                                               null_dita_processor,
                                               static_site_generator_formatter)
          silence_io_streams do
            publish_command.run(['github'])
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
              config_fetcher = double('config fetcher', fetch_config: config)

              publish_command = Commands::Bind.new(logger,
                                                   config_fetcher,
                                                   SpecGitAccessor,
                                                   file_system_accessor,
                                                   middleman_runner,
                                                   spider,
                                                   final_app_dir,
                                                   server_director,
                                                   File.absolute_path('.'),
                                                   null_dita_processor,
                                                   static_site_generator_formatter)
              publish_command.run(['github'])
            end.to raise_error "Your public host must be a single String."
          end
        end

        context 'when the hostname is a single string' do
          it 'contains the given pages in an XML sitemap' do
            book_dir = File.absolute_path('.')
            middleman_source_dir = File.join(book_dir, 'master_middleman', 'source')
            FileUtils.mkdir_p middleman_source_dir
            FileUtils.cp File.expand_path('../../../../fixtures/dogs_index.html', __FILE__), File.join(middleman_source_dir, 'index.html.md.erb')

            sections = [
                { 'repository' => {'name' => 'org/dogs-repo'} }
            ]

            config_hash = {
                'sections' => sections,
                'book_repo' => book,
                'public_host' => 'docs.dogs.com'
            }

            config = Configuration.new(logger, config_hash)
            config_fetcher = double('config fetcher', fetch_config: config)

            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 SpecGitAccessor,
                                                 file_system_accessor,
                                                 middleman_runner,
                                                 spider,
                                                 final_app_dir,
                                                 server_director,
                                                 File.absolute_path('.'),
                                                 null_dita_processor,
                                                 static_site_generator_formatter)
            publish_command.run(['github'])

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
          config_fetcher = double('config fetcher', fetch_config: config)

          publish_command = Commands::Bind.new(logger,
                                               config_fetcher,
                                               SpecGitAccessor,
                                               file_system_accessor,
                                               middleman_runner,
                                               spider,
                                               final_app_dir,
                                               server_director,
                                               File.absolute_path('.'),
                                               null_dita_processor,
                                               static_site_generator_formatter)
          publish_command.run(['github'])

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
          expect(fake_publisher).to receive(:publish).with anything, expected_cli_options, expected_output_paths, expected_publish_config
          publish_command.run(['local'])
        end
      end

      describe 'verbose mode' do
        context 'when the verbose flag is not set' do
          it 'suppresses detailed output' do
            sections = [
                {
                    'repository' => { 'name' => 'my-docs-org/repo-with-nonexistent-helper-method' },
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

            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 SpecGitAccessor,
                                                 file_system_accessor,
                                                 middleman_runner,
                                                 spider,
                                                 final_app_dir,
                                                 server_director,
                                                 File.absolute_path('.'),
                                                 null_dita_processor,
                                                 static_site_generator_formatter)
            begin
              real_stdout = $stdout
              $stdout = StringIO.new

              expect do
                publish_command.run(['github'])
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
                  'repository' => { 'name' => 'my-docs-org/repo-with-nonexistent-helper-method' },
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

          publish_command = Commands::Bind.new(logger,
                                               config_fetcher,
                                               SpecGitAccessor,
                                               file_system_accessor,
                                               middleman_runner,
                                               spider,
                                               final_app_dir,
                                               server_director,
                                               File.absolute_path('.'),
                                               null_dita_processor,
                                               static_site_generator_formatter)
          begin
            real_stdout = $stdout
            $stdout = StringIO.new

            expect do
              publish_command.run(['github', '--verbose'])
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
        context 'when the output directory does not yet exist' do
          def create_publish_command
            config_hash = {
                'sections' => [],
                'book_repo' => book,
                'public_host' => 'docs.dogs.com'
            }

            config = Configuration.new(logger, config_hash)
            config_fetcher = double('config fetcher', fetch_config: config)
            middleman_runner = MiddlemanRunner.new(logger, SpecGitAccessor)
            final_app_dir = File.absolute_path('final_app')
            spider = Spider.new(logger, app_dir: final_app_dir)
            server_director = ServerDirector.new(logger, directory: final_app_dir)

            Commands::Bind.new(logger,
                               config_fetcher,
                               SpecGitAccessor,
                               file_system_accessor,
                               middleman_runner,
                               spider,
                               final_app_dir,
                               server_director,
                               File.absolute_path('.'),
                               null_dita_processor,
                               static_site_generator_formatter)
          end

          it 'creates the output directory' do
            publish_command = create_publish_command

            output_dir = File.absolute_path('./output')

            expect(File.exists?(output_dir)).to eq false

            publish_command.run(['github'])

            expect(File.exists?(output_dir)).to eq true
          end

          it 'clears the output directory before running' do
            publish_command = create_publish_command

            output_dir = File.absolute_path('./output')
            FileUtils.mkdir_p output_dir
            pre_existing_file = File.join(output_dir, 'happy')
            FileUtils.touch pre_existing_file

            expect(File.exists?(pre_existing_file)).to eq true

            publish_command.run(['github'])

            expect(File.exists?(pre_existing_file)).to eq false
          end

          it 'clears and then copies the template_app skeleton inside final_app' do
            final_app_dir = File.absolute_path('./final_app')
            FileUtils.mkdir_p final_app_dir
            pre_existing_file = File.join(final_app_dir, 'happy')
            FileUtils.touch pre_existing_file

            publish_command = create_publish_command
            publish_command.run(['github'])

            expect(File.exists?(pre_existing_file)).to eq false
            copied_manifest = File.read File.join(final_app_dir, 'app.rb')
            template_manifest = File.read(File.expand_path('../../../../../template_app/app.rb', __FILE__))
            expect(copied_manifest).to eq(template_manifest)
          end
        end
      end
    end

    describe 'unit' do
      context 'when publishing from github' do

        context 'when the config contains dita sections' do
          it 'clones the dita sections to a dita directory' do
            logger = double('logger', log: true)
            version_control_system = double('vcs')
            fs_accessor = double('fs_accessor',
                                 remove_directory: true,
                                 make_directory: true,
                                 copy: true,
                                 copy_contents: true)
            static_site_generator = double('static_site_generator', run: true)
            sitemap_generator = double('sitemap_generator', has_broken_links?: false)
            server_director = double('server_director', use_server: true)
            static_site_generator_formatter = double('static_site_generator_formatter', format: nil)

            final_app_dir = ''

            user_config = {
              'book_repo' => 'my_dita_book',
              'public_host' => 'my public host',
              'dita_sections' => [
                {
                  'repository' => {
                    'name' => 'org/dita_section'
                  },
                  'ditamap_location' => 'path/to/dita.ditamap',
                  'directory' => 'my_dita_section'
                }
              ]
            }

            config_containing_dita_sections = Configuration.new(logger, user_config)
            config_fetcher = double('config fetcher', fetch_config: config_containing_dita_sections)

            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 version_control_system,
                                                 fs_accessor,
                                                 static_site_generator,
                                                 sitemap_generator,
                                                 final_app_dir,
                                                 server_director,
                                                 'irrelevant/path',
                                                 null_dita_processor,
                                                 static_site_generator_formatter)

            expect(version_control_system).to receive(:clone).with('git@github.com:org/dita_section',
                                                                   'my_dita_section',
                                                                   path: /output\/tmp\/dita_sections/).once

            publish_command.run(['github'])
          end

          it 'formats the processed DITA output to a format processable by the static site generator' do
            logger = double('logger', log: true)
            version_control_system = double('vcs', clone: nil)
            fs_accessor = double('fs_accessor',
                                 remove_directory: true,
                                 make_directory: true,
                                 copy: true,
                                 copy_contents: true)
            static_site_generator = double('static_site_generator', run: true)
            sitemap_generator = double('sitemap_generator', has_broken_links?: false)
            server_director = double('server_director', use_server: true)
            static_site_generator_formatter = double('static_site_generator_formatter')

            final_app_dir = ''

            user_config = {
                'book_repo' => 'my_dita_book',
                'public_host' => 'my public host',
                'dita_sections' => [
                    {
                        'repository' => {
                            'name' => 'org/dita_section',
                            'ref' => 'my-ref-SHA'
                        },
                        'ditamap_location' => 'path/to/dita.ditamap',
                        'directory' => 'my_dita_section'
                    }
                ]
            }

            config_containing_dita_sections = Configuration.new(logger, user_config)
            config_fetcher = double('config fetcher', fetch_config: config_containing_dita_sections)

            dita_processor = double('dita processor')
            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 version_control_system,
                                                 fs_accessor,
                                                 static_site_generator,
                                                 sitemap_generator,
                                                 final_app_dir,
                                                 server_director,
                                                 'base',
                                                 dita_processor,
                                                 static_site_generator_formatter)

            dita_section = DitaSection.new('base/output/tmp/dita_sections/my_dita_section',
                                           'path/to/dita.ditamap',
                                           'org/dita_section',
                                           'my-ref-SHA',
                                           'my_dita_section')
            allow(dita_processor).
              to receive(:process).
              with([dita_section], to: 'base/output/tmp/html_from_dita')

            expect(static_site_generator_formatter).
              to receive(:format).
              with('base/output/tmp/html_from_dita', 'base/output/tmp/site_generator_ready')

            publish_command.run(['github'])
          end

          it 'copies processed dita sections and all non-html files into static site generator directory' do
            logger = double('logger', log: true)
            version_control_system = double('vcs', clone: nil)
            fs_accessor = double('fs_accessor',
                                 remove_directory: true,
                                 make_directory: true,
                                 copy: true,
                                 copy_contents: true)
            static_site_generator = double('static_site_generator', run: true)
            sitemap_generator = double('sitemap_generator', has_broken_links?: false)
            server_director = double('server_director', use_server: true)
            static_site_generator_formatter = double('static_site_generator_formatter')

            final_app_dir = ''

            user_config = {
              'book_repo' => 'my_dita_book',
              'public_host' => 'my public host',
              'dita_sections' => [
                {
                  'repository' => {
                    'name' => 'org/dita_section',
                    'ref' => 'my-ref-SHA'
                  },
                  'ditamap_location' => 'path/to/dita.ditamap',
                  'directory' => 'my_dita_section'
                }
              ]
            }

            config_containing_dita_sections = Configuration.new(logger, user_config)
            config_fetcher = double('config fetcher', fetch_config: config_containing_dita_sections)

            dita_processor = double('dita processor')
            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 version_control_system,
                                                 fs_accessor,
                                                 static_site_generator,
                                                 sitemap_generator,
                                                 final_app_dir,
                                                 server_director,
                                                 'base',
                                                 dita_processor,
                                                 static_site_generator_formatter)

            dita_section = DitaSection.new('base/output/tmp/dita_sections/my_dita_section',
                                           'path/to/dita.ditamap',
                                           'org/dita_section',
                                           'my-ref-SHA',
                                           'my_dita_section')
            allow(dita_processor).
              to receive(:process).
              with([dita_section], to: 'base/output/tmp/html_from_dita')

            allow(static_site_generator_formatter).
              to receive(:format).
              with('base/output/tmp/html_from_dita', 'base/output/tmp/site_generator_ready')

            expect(fs_accessor).
                to receive(:copy_contents).
                       with('base/output/tmp/html_from_dita', /middleman\/source/)

            expect(fs_accessor).
              to receive(:copy_contents).
              with('base/output/tmp/site_generator_ready', /middleman\/source/)

            publish_command.run(['github'])
          end
        end
      end

      context 'when publishing from local' do
        context 'when the config contains dita sections' do
          it 'processes the dita sections from their local dir to a processed-dita directory' do
            logger = double('logger', log: true)
            version_control_system = double('vcs')
            fs_accessor = double('fs_accessor', remove_directory: true, make_directory: true, copy: true, copy_contents: true)
            static_site_generator = double('static_site_generator', run: true)
            sitemap_generator = double('sitemap_generator', has_broken_links?: false)
            server_director = double('server_director', use_server: true)
            static_site_generator_formatter = double('static_site_generator_formatter', format: nil)

            final_app_dir = ''
            user_config = {
                'book_repo' => 'my_dita_book',
                'public_host' => 'my public host',
                'dita_sections' => [
                    {
                        'repository' => {
                            'name' => 'org/dita_section',
                            'ref' => 'my-ref-SHA'
                        },
                        'ditamap_location' => 'path/to/dita.ditamap',
                        'directory' => 'my_dita_section',

                    }
                ]
            }
            config_containing_dita_sections = Configuration.new(logger, user_config)
            config_fetcher = double('config fetcher', fetch_config: config_containing_dita_sections)

            dita_processor = double('dita processor')
            publish_command = Commands::Bind.new(logger,
                                                 config_fetcher,
                                                 version_control_system,
                                                 fs_accessor,
                                                 static_site_generator,
                                                 sitemap_generator,
                                                 final_app_dir,
                                                 server_director,
                                                 '/parent-of-book/book',
                                                 dita_processor,
                                                 static_site_generator_formatter)

            expected_dita_section = DitaSection.new('/parent-of-book/my_dita_section',
                                           'path/to/dita.ditamap',
                                           'org/dita_section',
                                           'my-ref-SHA',
                                           'my_dita_section')

            expect(dita_processor).
                to receive(:process).
                       with([expected_dita_section], to: '/parent-of-book/book/output/tmp/html_from_dita').
                       and_return(['html_from_dita/my_dita_section'])

            publish_command.run(['local'])
          end
        end
      end
    end
  end
end
