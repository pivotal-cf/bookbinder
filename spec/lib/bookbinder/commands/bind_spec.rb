require_relative '../../../../lib/bookbinder/commands/bind'
require_relative '../../../../lib/bookbinder/commands/bind/directory_preparer'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/dita_command_creator'
require_relative '../../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/ingest/cloner_factory'
require_relative '../../../../lib/bookbinder/ingest/section_repository'
require_relative '../../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/postprocessing/sitemap_writer'
require_relative '../../../../lib/bookbinder/preprocessing/dita_preprocessor'
require_relative '../../../../lib/bookbinder/preprocessing/link_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/preprocessing/preprocessor'
require_relative '../../../../lib/bookbinder/server_director'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../../lib/bookbinder/spider'
require_relative '../../../../lib/bookbinder/subnav_formatter'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../helpers/git_fake'
require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/redirection'
require_relative '../../../helpers/use_fixture_repo'

module Bookbinder
  describe Commands::Bind do
    class FakeArchiveMenuConfig
      def generate(base_config, *)
        base_config
      end
    end

    include SpecHelperMethods

    use_fixture_repo

    def bind_cmd(partial_args = {})
      bind_version_control_system = partial_args.fetch(:version_control_system, Bookbinder::GitFake.new)
      bind_logger = partial_args.fetch(:logger, logger)
      null_streams = {success: Sheller::DevNull.new, out: Sheller::DevNull.new, err: Sheller::DevNull.new}
      Commands::Bind.new(
        partial_args.fetch(:streams, null_streams),
        OutputLocations.new(
          final_app_dir: partial_args.fetch(:final_app_directory, final_app_dir),
          context_dir: partial_args.fetch(:context_dir, File.absolute_path('.'))
        ),
        partial_args.fetch(:config_fetcher, double('config fetcher', fetch_config: config)),
        partial_args.fetch(:archive_menu_config, archive_menu_config),
        partial_args.fetch(:file_system_accessor, file_system_accessor),
        partial_args.fetch(:static_site_generator, middleman_runner),
        partial_args.fetch(:sitemap_writer, sitemap_writer),
        partial_args.fetch(:preprocessor, preprocessor),
        partial_args.fetch(:cloner_factory, Ingest::ClonerFactory.new(null_streams, file_system_accessor, GitFake.new)),
        partial_args.fetch(:section_repository, Ingest::SectionRepository.new),
        partial_args.fetch(:directory_preparer, Commands::BindComponents::DirectoryPreparer.new(file_system_accessor)))
    end

    def random_port
      rand(49152..65535)
    end

    let(:archive_menu_config) { FakeArchiveMenuConfig.new }
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
    let(:book) { 'fantastic/book' }
    let(:command_creator) { double('command creator', convert_to_html_command: 'stubbed command') }
    let(:config) { Config::Configuration.parse(config_hash) }
    let(:config_hash) { base_config_hash }
    let(:preprocessor) {
      Preprocessing::Preprocessor.new(
         Preprocessing::DitaPreprocessor.new(static_site_generator_formatter, file_system_accessor, command_creator, sheller),
         Preprocessing::LinkToSiteGenDir.new(file_system_accessor),
      )
    }
    let(:document_parser) { HtmlDocumentManipulator.new }
    let(:file_system_accessor) { LocalFileSystemAccessor.new }
    let(:final_app_dir) { File.absolute_path('final_app') }
    let(:git_client) { GitClient.new }
    let(:logger) { NilLogger.new }
    let(:middleman_runner) { MiddlemanRunner.new(file_system_accessor, Sheller.new) }
    let(:success) { double('success', success?: true) }
    let(:failure) { double('failure', success?: false) }
    let(:sheller) { double('sheller', run_command: success) }
    let(:sitemap_writer) { Postprocessing::SitemapWriter.build(logger, final_app_dir, random_port) }
    let(:static_site_generator_formatter) { DitaHtmlToMiddlemanFormatter.new(file_system_accessor, subnav_formatter, document_parser) }
    let(:subnav_formatter) { SubnavFormatter.new }

    describe "both local and remote" do
      context "when site generation fails" do
        it "returns a nonzero exit code" do
          generator = instance_double('Bookbinder::MiddlemanRunner')
          fs = instance_double('Bookbinder::LocalFileSystemAccessor')
          disallowed_streams = {}

          command = bind_cmd(streams: disallowed_streams,
                             file_system_accessor: fs,
                             static_site_generator: generator,
                             sitemap_writer: double('disallowed sitemap writer'),
                             section_repository: instance_double('Ingest::SectionRepository', fetch: []))

          allow(fs).to receive(:file_exist?) { false }
          allow(generator).to receive(:run) { failure }

          expect(command.run(['local'])).to be_nonzero
        end
      end

      it "copies a redirects file from the current directory to the final app directory, prior to site generation" do
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        generator = instance_double('Bookbinder::MiddlemanRunner')
        command = bind_cmd(file_system_accessor: fs,
                           static_site_generator: generator,
                           sitemap_writer: double('sitemap writer').as_null_object)

        allow(fs).to receive(:file_exist?).with('redirects.rb') { true }
        allow(fs).to receive(:copy)

        expect(fs).to receive(:copy).with('redirects.rb', Pathname(File.absolute_path('final_app'))).ordered
        expect(generator).to receive(:run).ordered { success }

        command.run(['local'])
      end

      it "doesn't attempt to copy the redirect file if it doesn't exist" do
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        generator = instance_double('Bookbinder::MiddlemanRunner')
        command = bind_cmd(file_system_accessor: fs,
                           static_site_generator: generator,
                           sitemap_writer: double('sitemap writer').as_null_object)

        allow(fs).to receive(:file_exist?).with('redirects.rb') { false }

        expect(generator).to receive(:run).ordered { success }
        expect(fs).to receive(:copy).ordered

        command.run(['local'])
      end

      it "prepares directories and then preprocesses fetched sections" do
        directory_preparer = instance_double('BindComponents::DirectoryPreparer')
        output_locations = OutputLocations.new(context_dir: ".")
        preprocessor = instance_double('Preprocessing::Preprocessor')
        merged_streams = { out: instance_of(Sheller::DevNull) }

        cloner = instance_double('Ingest::Cloner')
        cloner_factory = instance_double('Ingest::ClonerFactory')
        allow(cloner_factory).to receive(:produce).with(File.expand_path('..')) { cloner}

        section_config = Config::SectionConfig.new({'directory' => 'foo'})
        config = Config::Configuration.new({book_repo: "some_book", sections: [section_config]})
        sections = [Section.new('fake/path', 'foo/bar'), Section.new('other/path', 'cat/dog')]

        section_repository = instance_double('Ingest::SectionRepository')
        allow(section_repository).to receive(:fetch).
          with(configured_sections: [section_config],
               destination_dir: output_locations.cloned_preprocessing_dir,
               ref_override: nil,
               cloner: cloner,
               streams: merged_streams) { sections }

        expect(directory_preparer).to receive(:prepare_directories).
          with(File.expand_path('../../../../', __dir__),
               output_locations,
               File.absolute_path('master_middleman')).ordered

        expect(preprocessor).to receive(:preprocess).
          with(sections,
               output_locations,
               options: [],
               output_streams: merged_streams).ordered

        Commands::Bind.new(
            {},
            output_locations,
            instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
            double('decorator', generate: config),
            instance_double('LocalFileSystemAccessor', file_exist?: false),
            instance_double('MiddlemanRunner', run: failure),
            instance_double('Postprocessing::SitemapWriter'),
            preprocessor,
            cloner_factory,
            section_repository,
            directory_preparer
        ).run(['local'])
      end

      context 'when configured with a layout repo' do
        let(:cloner) { double('cloner') }
        let(:factory) { double('cloner factory') }
        let(:config) { Config::Configuration.new(sections: [],
                                                 book_repo: '',
                                                 public_host: '',
                                                 layout_repo: 'my/configuredrepo') }
        let(:null_sitemap_writer) { double('sitemap writer', write: double(has_broken_links?: false)) }
        let(:null_site_generator) { double('site gen', run: success) }
        let(:null_fs_accessor) { double('fs accessor').as_null_object }

        it 'sets the repo as the layout repo path when prepping dirs' do
          received_output_locations = nil
          directory_preparer = double('dir preparer')
          allow(directory_preparer).to receive(:prepare_directories)

          bind = bind_cmd(cloner_factory: factory,
                          file_system_accessor: null_fs_accessor,
                          static_site_generator: null_site_generator,
                          sitemap_writer: null_sitemap_writer,
                          directory_preparer: directory_preparer)

          allow(factory).to receive(:produce).with(nil) { cloner }
          allow(cloner).to receive(:call).
            with(hash_including(source_repo_name: "my/configuredrepo")) {
            Ingest::WorkingCopy.new(copied_to: 'foo/repo')
          }

          bind.run(['remote'])

          expect(directory_preparer).to have_received(:prepare_directories).
            with(anything, anything, Pathname('foo/repo'))
        end
      end
    end

    it 'creates a directory per repo with the generated html from middleman' do
      silence_io_streams do
        bind_cmd.run(['remote'])
      end

      final_app_dir = File.absolute_path('final_app')

      index_html = File.read File.join(final_app_dir, 'public', 'dogs', 'index.html')
      expect(index_html).to include 'breeds.png'

      other_index_html = File.read File.join(final_app_dir, 'public', 'foods/sweet', 'index.html')
      expect(other_index_html).to include 'This is a Markdown Page'

      third_index_html = File.read File.join(final_app_dir, 'public', 'foods/savory', 'index.html')
      expect(third_index_html).to include 'This is another Markdown Page'
    end

    context 'when there are invalid arguments' do
      it 'raises Cli::InvalidArguments' do
        expect {
          bind_cmd.run(['blah', 'blah', 'whatever'])
        }.to raise_error(CliError::InvalidArguments)

        expect {
          bind_cmd.run([])
        }.to raise_error(CliError::InvalidArguments)
      end
    end

    describe 'using template variables' do
      it 'includes them in the final site' do
        bind_cmd(config_fetcher: double('config fetcher', fetch_config: Config::Configuration.new(
          sections: [
            Config::SectionConfig.new(
              'repository' => {'name' => 'fantastic/my-variable-repo'},
              'directory' => 'var-repo')
          ],
          book_repo: book,
          cred_repo: 'my-org/my-creds',
          public_host: 'example.com',
          template_variables: {'name' => 'Spartacus'}
        ))).run(['remote'])

        final_app_dir = File.absolute_path('final_app')
        index_html = File.read File.join(final_app_dir, 'public', 'var-repo', 'variable_index.html')
        expect(index_html).to include 'My variable name is Spartacus.'
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
              fetch_config: Config::Configuration.parse(
                'sections' => [ {'repository' => {'name' => 'org/dogs-repo'}} ],
                'book_repo' => 'fantastic/book',
                'cred_repo' => 'my-org/my-creds',
                'public_host' => 'docs.dogs.com'
              )))

          command.run(['remote'])

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
    end

    describe 'verbose mode' do
      include Redirection

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

          config = Config::Configuration.parse(config_hash)
          config_fetcher = double('config fetcher', fetch_config: config)

          command = bind_cmd(config_fetcher: config_fetcher)
          collected_output = capture_stdout {
            begin
              command.run(['remote'])
            rescue SystemExit
            end
          }

          expect(collected_output).not_to match(/error.*build\/index.html/)
          expect(collected_output).not_to match(/undefined local variable or method `function_that_does_not_exist'/)
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

        config = Config::Configuration.parse(config_hash)
        config_fetcher = double('config fetcher', fetch_config: config)
        streams = { out: StringIO.new, success: StringIO.new }

        command = bind_cmd(streams: streams, config_fetcher: config_fetcher)
        begin
          command.run(['remote', '--verbose'])
        rescue SystemExit
        end

        # Middleman puts errors to stdout when asked for --verbose
        output = streams[:out].tap(&:rewind).read
        expect(output).to match(/error.*build/)
        expect(output).to match(/undefined local variable or method `function_that_does_not_exist'/)
      end
    end
  end
end
