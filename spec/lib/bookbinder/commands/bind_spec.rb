require_relative '../../../../lib/bookbinder/commands/bind'
require_relative '../../../../lib/bookbinder/commands/bind/directory_preparer'
require_relative '../../../../lib/bookbinder/config/bind_config_factory'
require_relative '../../../../lib/bookbinder/ingest/cloner_factory'
require_relative '../../../../lib/bookbinder/post_production/sitemap_writer'
require_relative '../../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/redirection'
require_relative '../../../helpers/git_fake'
require_relative '../../../helpers/use_fixture_repo'

require_relative '../../../../lib/bookbinder/configuration'
require_relative '../../../../lib/bookbinder/dita_command_creator'
require_relative '../../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../../../lib/bookbinder/dita_preprocessor'
require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../../lib/bookbinder/spider'
require_relative '../../../../lib/bookbinder/server_director'
require_relative '../../../../lib/bookbinder/subnav_formatter'

module Bookbinder
  describe Commands::Bind do

    class FakeArchiveMenuConfig
      def generate(base_config, *)
        base_config
      end
    end

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
      bind_version_control_system = partial_args.fetch(:version_control_system, Bookbinder::GitFake.new)
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
                         partial_args.fetch(:cloner_factory, Ingest::ClonerFactory.new(logger, file_system_accessor, GitFake.new)),
                         DitaSectionGathererFactory.new(bind_version_control_system, bind_logger),
                         Repositories::SectionRepository.new(logger),
                         partial_args.fetch(:command_creator, command_creator),
                         partial_args.fetch(:sheller, sheller),
                         partial_args.fetch(:directory_preparer,
                                            Commands::BindComponents::DirectoryPreparer.new(bind_logger,
                                                                                            file_system_accessor,
                                                                                            bind_version_control_system)))
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
    let(:dita_preprocessor) { DitaPreprocessor.new(static_site_generator_formatter, file_system_accessor) }
    let(:document_parser) { HtmlDocumentManipulator.new }
    let(:file_system_accessor) { LocalFileSystemAccessor.new }
    let(:final_app_dir) { File.absolute_path('final_app') }
    let(:git_client) { GitClient.new }
    let(:logger) { NilLogger.new }
    let(:middleman_runner) { MiddlemanRunner.new(logger, GitFake.new) }
    let(:sheller) { double('sheller', run_command: double('status', success?: true)) }
    let(:sitemap_writer) { PostProduction::SitemapWriter.build(logger, final_app_dir, random_port) }
    let(:static_site_generator_formatter) { DitaHtmlToMiddlemanFormatter.new(file_system_accessor, subnav_formatter, document_parser) }
    let(:subnav_formatter) { SubnavFormatter.new }

    describe "when the DITA processor fails" do
      it "raises an exception" do
        preprocessor = double('preprocessor')
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: Sheller.new,
                           command_creator: double('command creator',
                                                   convert_to_html_command: 'false'))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        allow(preprocessor).to receive(:preprocess).and_yield(
          DitaSection.new(nil, nil, nil, 'foo', nil, nil, output_locations)
        )
        expect { command.run(['local']) }.to raise_exception(Commands::Bind::DitaToHtmlLibraryFailure)
      end
    end

    describe "DITA command output" do
      include Redirection

      it "sends to stdout when --verbose" do
        preprocessor = double('preprocessor')
        stdout_and_stderr_producer = 'echo foo; >&2 echo bar'
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: Sheller.new,
                           command_creator: double('command creator',
                                                   convert_to_html_command: stdout_and_stderr_producer))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        allow(preprocessor).to receive(:preprocess).and_yield(
          DitaSection.new(nil, nil, nil, 'foo', nil, nil, output_locations)
        )
        stdout = capture_stdout { swallow_stderr { command.run(['local', '--verbose']) } }
        expect(stdout.lines.first).to eq("foo\n")
      end

      it "doesn't send to stdout when not --verbose" do
        preprocessor = double('preprocessor')
        stdout_and_stderr_producer = 'echo foo; >&2 echo bar'
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: Sheller.new,
                           command_creator: double('command creator',
                                                   convert_to_html_command: stdout_and_stderr_producer))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        allow(preprocessor).to receive(:preprocess).and_yield(
          DitaSection.new(nil, nil, nil, 'foo', nil, nil, output_locations)
        )
        stdout = capture_stdout { swallow_stderr { command.run(['local']) } }
        expect(stdout).to eq("")
      end

      it "sends to stderr in red even when not --verbose" do
        preprocessor = double('preprocessor')
        stdout_and_stderr_producer = 'echo foo; >&2 echo bar'
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: Sheller.new,
                           command_creator: double('command creator',
                                                   convert_to_html_command: stdout_and_stderr_producer))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        allow(preprocessor).to receive(:preprocess).and_yield(
          DitaSection.new(nil, nil, nil, 'foo', nil, nil, output_locations)
        )
        stderr = capture_stderr { swallow_stdout { command.run(['local']) } }
        expect(stderr).to eq("\e[31mbar\n\e[0m")
      end
    end

    describe "when DITA flags are passed at the command line" do
      it 'the DITA conversion command includes the same flags' do
        preprocessor = double('preprocessor')
        sheller = double('sheller')
        command = bind_cmd(dita_preprocessor: preprocessor,
                           sheller: sheller,
                           command_creator: DitaCommandCreator.new('path/to/dita/ot/library'))
        output_locations = OutputLocations.new(context_dir: Pathname('foo'))
        expected_classpath = 'path/to/dita/ot/library/lib/xercesImpl.jar:' +
                             'path/to/dita/ot/library/lib/xml-apis.jar:' +
                             'path/to/dita/ot/library/lib/resolver.jar:' +
                             'path/to/dita/ot/library/lib/commons-codec-1.4.jar:' +
                             'path/to/dita/ot/library/lib/icu4j.jar:' +
                             'path/to/dita/ot/library/lib/saxon/saxon9-dom.jar:' +
                             'path/to/dita/ot/library/lib/saxon/saxon9.jar:target/classes:' +
                             'path/to/dita/ot/library:' +
                             'path/to/dita/ot/library/lib/:' +
                             'path/to/dita/ot/library/lib/dost.jar'
        successful_exit = instance_double(Process::Status, success?: true)

        allow(preprocessor).to receive(:preprocess).and_yield(
                                   DitaSection.new('path/to/local/repo',
                                                   'path/to/map.ditamap',
                                                   nil,
                                                   'foo',
                                                   nil,
                                                   nil,
                                                   output_locations)
                               )
        expect(sheller).to receive(:run_command).with("export CLASSPATH=#{expected_classpath}; " +
                                                      "ant -f path/to/dita/ot/library " +
                                                      "-Doutput.dir='foo/output/dita/html_from_dita/foo' " +
                                                      "-Dargs.input='path/to/local/repo/path/to/map.ditamap' " +
                                                      "-Dargs.filter='' " +
                                                      "-Dbasedir='/' " +
                                                      "-Dtranstype='tocjs' " +
                                                      "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
                                                      "-Dgenerate.copy.outer='2' " +
                                                      "-Douter.control='warn' " +
                                                      "-Dclean.temp='no' ",
                                                    anything)
                                                  .and_return(successful_exit)
        silence_io_streams do
          command.run(['local', '--verbose', "--dita-flags=clean.temp='no'"])
        end
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

      context 'when code snippets are yielded' do
        let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

        context 'and the code repo is present' do
          it 'can find code example repos locally rather than going to github' do
            expect(GitFake.new).to_not receive(:clone)

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

      context 'when configured with a layout repo' do
        let(:cloner) { double('cloner') }
        let(:factory) { double('cloner factory') }
        let(:config) { Configuration.new(logger, 'book_repo' => '', 'public_host' => '', 'layout_repo' => 'my/configuredrepo') }
        let(:config_fetcher) { double('config fetcher', fetch_config: config) }
        let(:null_sitemap_writer) { double('sitemap writer', write: double(has_broken_links?: false)) }
        let(:null_site_generator) { double('site gen', run: nil) }
        let(:null_fs_accessor) { double('fs accessor', copy: nil) }

        it 'clones the repo' do
          bind = bind_cmd(cloner_factory: factory,
                          config_fetcher: config_fetcher,
                          file_system_accessor: null_fs_accessor,
                          static_site_generator: null_site_generator,
                          sitemap_writer: null_sitemap_writer,
                          directory_preparer: double('dir preparer', prepare_directories: nil))

          allow(factory).to receive(:produce).with('github', nil) { cloner }

          expect(cloner).to receive(:call).
            with(source_repo_name: "my/configuredrepo", destination_parent_dir: anything) {
            Ingest::WorkingCopy.new(repo_dir: 'foo', full_name: 'some/repo')
          }

          bind.run(['github'])
        end

        it 'sets the repo as the layout repo path when prepping dirs' do
          received_output_locations = nil
          directory_preparer = Object.new
          directory_preparer.define_singleton_method(:prepare_directories) {|_, _, output_locations, _|
            received_output_locations = output_locations
          }

          bind = bind_cmd(cloner_factory: factory,
                          config_fetcher: config_fetcher,
                          file_system_accessor: null_fs_accessor,
                          static_site_generator: null_site_generator,
                          sitemap_writer: null_sitemap_writer,
                          directory_preparer: directory_preparer)

          allow(factory).to receive(:produce) { cloner }
          allow(cloner).to receive(:call) { Ingest::WorkingCopy.new(repo_dir: 'foo',
                                                                    full_name: 'some/repo') }

          bind.run(['github'])

          expect(received_output_locations.layout_repo_dir).to eq(Pathname('foo/repo'))
        end
      end

      it 'creates a directory per repo with the generated html from middleman' do
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
          pub = Pathname('final_app').join('public')
          expect(pub.join('dogs/index.html').read).to include 'images/breeds.png'
          expect(pub.join('foods/sweet/index.html').read).to include 'This is a Markdown Page'
          expect(pub.join('foods/savory/index.html').read).to include 'This is another Markdown Page'
          expect(pub.join('v1/dogs/index.html').read).to include 'images/breeds.png'
          expect(pub.join('v1/foods/sweet/index.html').read).to include 'This is a Markdown Page'
          expect(pub.join('v1/foods/savory/index.html')).not_to exist
          expect(pub.join('v2/dogs/index.html').read).to include('images/breeds.png')
          expect(pub.join('v2/foods/sweet/index.html').read).to include 'This is a Markdown Page'
          expect(pub.join('v2/foods/savory/index.html').read).to include 'This is another Markdown Page'
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
      context 'when configured with a single host' do
        use_fixture_repo 'sitemap_tester'

        around do |example|
          $sitemap_debug = ENV['SITEMAP_DEBUG']
          example.run
          $sitemap_debug = nil
        end

        it 'contains the given pages in an XML sitemap' do
          command = bind_cmd(
            config_fetcher: double(
              'config fetcher',
              fetch_config: Configuration.new(
                logger,
                'sections' => [ {'repository' => {'name' => 'org/dogs-repo'}} ],
                'book_repo' => 'fantastic/book',
                'cred_repo' => 'my-org/my-creds',
                'public_host' => 'docs.dogs.com'
              )))

          command.run(['github'])

          sitemap_path = Pathname('final_app').join('public', 'sitemap.xml')

          expect(sitemap_path).to have_sitemap_locations %w(
              http://docs.dogs.com/index.html
              http://docs.dogs.com/dogs-repo/index.html
              http://docs.dogs.com/dogs-repo/big_dogs/index.html
              http://docs.dogs.com/dogs-repo/big_dogs/great_danes/index.html
          )
        end

        matcher :have_sitemap_locations do |links|
          match do |sitemap_path|
            @doc = Nokogiri::XML(sitemap_path.open)
            @doc.css('loc').map(&:text).map(&:to_s).sort == links.sort
          end

          failure_message do |sitemap_path|
            <<-MESSAGE
Expected sitemap to have the following links:
#{links.sort.join("\n")}

But it actually had these:
#{@doc.css('loc').map(&:text).sort.join("\n")}

* Sitemap *
Path:
#{sitemap_path}

Content:
#{sitemap_path.read}
            MESSAGE
          end
        end
      end

      context 'when configured with more than one host' do
        it 'raises an exception' do
          command = bind_cmd(
            config_fetcher: double(
              'config fetcher',
              fetch_config: Configuration.new(
                logger,
                'sections' => [{'repository' => {'name' => 'org/dogs-repo'}}],
                'book_repo' => 'some/book',
                'cred_repo' => 'my-org/my-creds',
                'public_host' => ['host1.runpivotal.com', 'host2.pivotal.io'],
              )))

          expect { command.run(['github']) }.
            to raise_error "Your public host must be a single String."
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
        middleman_runner = MiddlemanRunner.new(logger, GitFake.new)
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
