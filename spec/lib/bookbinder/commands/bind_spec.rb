require_relative '../../../../lib/bookbinder/commands/bind'
require_relative '../../../../lib/bookbinder/commands/components/bind/directory_preparer'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/ingest/cloner_factory'
require_relative '../../../../lib/bookbinder/ingest/section_repository'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/preprocessing/link_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/server_director'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../helpers/git_fake'
require_relative '../../../helpers/middleman'
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

    let(:null_link_checker) { double('link checker', check!: nil, has_errors?: false) }
    let(:null_fs_accessor) { double('fs accessor').as_null_object }
    let(:null_preprocessor) { instance_double('Bookbinder::Preprocessing::LinkToSiteGenDir', preprocess: nil) }
    let(:null_middleman_runner) { instance_double('Bookbinder::MiddlemanRunner', run: success) }
    let(:null_logger) { double('deprecated logger').as_null_object }
    let(:null_directory_preparer) { instance_double('Bookbinder::Commands::Components::Bind::DirectoryPreparer', prepare_directories: nil) }
    let(:null_cloner) { double('cloner').as_null_object }
    let(:null_cloner_factory) { instance_double('Bookbinder::Ingest::ClonerFactory', produce: null_cloner) }
    let(:null_section_repository) { instance_double('Ingest::SectionRepository', fetch: []) }
    let(:null_dep) { double('dependency').as_null_object }

    let(:real_fs_accessor) { LocalFilesystemAccessor.new }
    let(:real_preprocessor) { Preprocessing::LinkToSiteGenDir.new(real_fs_accessor, null_dep) }
    let(:real_middleman_runner) { MiddlemanRunner.new(real_fs_accessor, Sheller.new) }

    let(:archive_menu_config) { FakeArchiveMenuConfig.new }
    let(:success) { double('success', success?: true) }
    let(:failure) { double('failure', success?: false) }

    def bind_cmd(partial_args = {})
      null_streams = {success: Sheller::DevNull.new, out: Sheller::DevNull.new, err: Sheller::DevNull.new}
      stub_config = Config::Configuration.new(sections: [],
                                              book_repo: 'fantastic/book',
                                              public_host: 'example.com',
                                              archive_menu: [])
      Commands::Bind.new(
        partial_args.fetch(:streams, null_streams),
        output_locations: partial_args.fetch(:output_locations, OutputLocations.new(
          final_app_dir: partial_args.fetch(:final_app_directory, File.absolute_path('final_app')),
          context_dir: partial_args.fetch(:context_dir, File.absolute_path('.'))
        )),
        config_fetcher: partial_args.fetch(:config_fetcher, double('config fetcher', fetch_config: stub_config)),
        config_decorator: partial_args.fetch(:archive_menu_config, archive_menu_config),
        file_system_accessor: partial_args.fetch(:file_system_accessor, null_fs_accessor),
        middleman_runner: partial_args.fetch(:middleman_runner, null_middleman_runner),
        link_checker: partial_args.fetch(:link_checker, null_link_checker),
        preprocessor: partial_args.fetch(:preprocessor, null_preprocessor),
        cloner_factory: partial_args.fetch(:cloner_factory, Ingest::ClonerFactory.new(null_streams, null_fs_accessor, GitFake.new)),
        section_repository: partial_args.fetch(:section_repository, Ingest::SectionRepository.new),
        directory_preparer: partial_args.fetch(:directory_preparer, Commands::Components::Bind::DirectoryPreparer.new(real_fs_accessor))
      )
    end

    it "prepares directories and then preprocesses fetched sections" do
      directory_preparer = instance_double('Components::Bind::DirectoryPreparer')
      output_locations = OutputLocations.new(context_dir: ".")
      preprocessor = instance_double('Preprocessing::Preprocessor')
      base_streams = { err: double('stream').as_null_object }
      merged_streams = base_streams.merge({ out: instance_of(Streams::FilterStream) })

      cloner = instance_double('Ingest::Cloner')
      cloner_factory = instance_double('Ingest::ClonerFactory')
      allow(cloner_factory).to receive(:produce).with(File.expand_path('..')) { cloner}

      section_config = Config::SectionConfig.new({'directory' => 'foo'})
      config = Config::Configuration.new({book_repo: "some_book", sections: [section_config]})
      sections = [Section.new('fake/path', 'foo/bar'), Section.new('other/path', 'cat/dog')]

      section_repository = instance_double('Ingest::SectionRepository')
      allow(section_repository).to receive(:fetch).with(
                                                    configured_sections: [section_config],
                                                    destination_dir: output_locations.cloned_preprocessing_dir,
                                                    ref_override: nil,
                                                    cloner: cloner,
                                                    streams: base_streams
                                   ) { sections }

      expect(directory_preparer).to receive(:prepare_directories).with(
                                        config,
                                        File.expand_path('../../../../', __dir__),
                                        output_locations,
                                        cloner,
                                        ref_override: nil
                                    ).ordered

      expect(preprocessor).to receive(:preprocess).with(
                                  sections,
                                  output_locations,
                                  options: { dita_flags: nil, require_valid_subnav_links: false },
                                  output_streams: merged_streams,
                                  config: config
                              ).ordered

      Commands::Bind.new(
          base_streams,
          output_locations: output_locations,
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: double('decorator', generate: config),
          file_system_accessor: instance_double('LocalFilesystemAccessor', file_exist?: false),
          middleman_runner: instance_double('MiddlemanRunner', run: failure),
          link_checker: null_link_checker,
          preprocessor: preprocessor,
          cloner_factory: cloner_factory,
          section_repository: section_repository,
          directory_preparer: directory_preparer
      ).run('local')
    end

    it "can tell the preprossesor to check the links in the subnav when binding locally" do
      bind_cmd.run('local', false, nil, true)

      expect(null_preprocessor).to have_received(:preprocess).with(instance_of(Array), instance_of(OutputLocations),
        hash_including(options: hash_including(require_valid_subnav_links: true)))
    end

    it "always tells the preprocessor to check the subnav links when binding remotely" do
      bind_cmd.run('remote', false, nil, false)

      expect(null_preprocessor).to have_received(:preprocess).with(instance_of(Array), instance_of(OutputLocations),
      hash_including(options: hash_including(require_valid_subnav_links: true)))
    end

    it "copies a redirects file from the current directory to the final app directory, prior to site generation" do
      fs = instance_double('Bookbinder::LocalFilesystemAccessor')
      generator = instance_double('Bookbinder::MiddlemanRunner')
      command = bind_cmd(file_system_accessor: fs,
        middleman_runner: generator,
        link_checker: null_link_checker)

      allow(fs).to receive(:file_exist?).with('redirects.rb') { true }
      allow(fs).to receive(:copy)

      expect(fs).to receive(:copy).with('redirects.rb', Pathname(File.absolute_path('final_app'))).ordered
      expect(generator).to receive(:run).ordered { success }

      command.run('local')
    end

    it "doesn't attempt to copy the redirect file if it doesn't exist" do
      fs = instance_double('Bookbinder::LocalFilesystemAccessor')
      generator = instance_double('Bookbinder::MiddlemanRunner')
      command = bind_cmd(file_system_accessor: fs,
        middleman_runner: generator,
        link_checker: null_link_checker)

      allow(fs).to receive(:file_exist?).with('redirects.rb') { false }

      expect(generator).to receive(:run).ordered { success }
      expect(fs).to receive(:copy).ordered

      command.run('local')
    end

    it "runs Middleman build" do
      base_streams = { err: double('stream').as_null_object }
      merged_streams = base_streams.merge({ out: instance_of(Streams::FilterStream) })
      output_locations = OutputLocations.new(context_dir: ".", final_app_dir: "foo")
      runner = instance_double('MiddlemanRunner')

      section_config = Config::SectionConfig.new({})
      config = Config::Configuration.new({book_repo: "some_book", sections: [section_config], public_host: "some.book.domain"})
      section = Section.new('fake/path', 'foo/bar')

      cloner = instance_double('Ingest::Cloner')

      section_repository = instance_double('Ingest::SectionRepository')
      allow(section_repository).to receive(:fetch).with(
          configured_sections: [section_config],
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: nil,
          cloner: cloner,
          streams: base_streams
        ) { [section] }

      expect(runner).to receive(:run).with("build --verbose",
          streams: merged_streams,
          output_locations: output_locations,
          config: config,
          local_repo_dir: File.expand_path(".."),
          subnavs: section.subnav,
          proof: false,
          product_info: {"bar"=>nil}) { failure }

      Commands::Bind.new(
        base_streams,
        output_locations: output_locations,
        config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
        config_decorator: double('decorator', generate: config),
        file_system_accessor: null_fs_accessor,
        middleman_runner: runner,
        link_checker: null_link_checker,
        preprocessor: null_preprocessor,
        cloner_factory: instance_double('Ingest::ClonerFactory', produce: cloner),
        section_repository: section_repository,
        directory_preparer: null_directory_preparer
      ).run('local')
    end

    it "returns a nonzero exit code when Middleman fails" do
      middleman_runner = instance_double('Bookbinder::MiddlemanRunner')
      fs = instance_double('Bookbinder::LocalFilesystemAccessor')
      streams = { err: double('stream') }

      command = bind_cmd(streams: streams,
                         file_system_accessor: fs,
                         middleman_runner: middleman_runner,
                         link_checker: null_link_checker,
                         section_repository: instance_double('Ingest::SectionRepository', fetch: []))

      allow(fs).to receive(:file_exist?) { false }
      allow(middleman_runner).to receive(:run) { failure }

      expect(streams[:err]).to receive(:puts).with(include('--verbose'))
      expect(command.run('local')).to be_nonzero
    end

    it "writes required files to output directory and outputs success message" do
      fs = instance_double('Bookbinder::LocalFilesystemAccessor', file_exist?: false)

      streams = { success: double('stream') }

      output_locations = OutputLocations.new(final_app_dir: 'whatever_final_app', context_dir: ".")
      config = Config::Configuration.new({public_host: 'some.site.io'})

      expect(fs).to receive(:copy).with(output_locations.build_dir, output_locations.public_dir).ordered
      expect(null_link_checker).to receive(:check!).with(config.broken_link_exclusions).ordered

      expect(streams[:success]).to receive(:puts).with(include(output_locations.final_app_dir.to_s))

      Commands::Bind.new(
        streams,
        output_locations: output_locations,
        config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
        config_decorator: double('decorator', generate: config),
        file_system_accessor: fs,
        middleman_runner: instance_double('Bookbinder::MiddlemanRunner', run: success),
        link_checker: null_link_checker,
        preprocessor: null_preprocessor,
        cloner_factory: null_cloner_factory,
        section_repository: null_section_repository,
        directory_preparer: null_directory_preparer
      ).run('local')
    end

    context "with broken links" do
      it "exits a non-zero exit code" do
        output_locations = OutputLocations.new(final_app_dir: 'some_other_final_app', context_dir: ".")
        config = Config::Configuration.new({public_host: 'some.site.io'})

        link_checker = double(:link_checker, check!: nil)
        allow(link_checker).to receive(:has_errors?) { true }

        command = Commands::Bind.new(
          double('streams').as_null_object,
          output_locations: output_locations,
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: double('decorator', generate: config),
          file_system_accessor: null_fs_accessor,
          middleman_runner: null_middleman_runner,
          link_checker: link_checker,
          preprocessor: null_preprocessor,
          cloner_factory: null_cloner_factory,
          section_repository: null_section_repository,
          directory_preparer: null_directory_preparer
        )

        expect(command.run('local')).to be_nonzero
      end
    end

    context "without broken links" do
      it "exits a zero exit code" do
        output_locations = OutputLocations.new(final_app_dir: 'some_other_final_app', context_dir: ".")
        config = Config::Configuration.new({public_host: 'some.site.io'})

        link_checker = double(:link_checker, check!: nil)
        allow(link_checker).to receive(:has_errors?) { false }

        command = Commands::Bind.new(
          double('streams').as_null_object,
          output_locations: output_locations,
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: double('decorator', generate: config),
          file_system_accessor: null_fs_accessor,
          middleman_runner: null_middleman_runner,
          link_checker: link_checker,
          preprocessor: null_preprocessor,
          cloner_factory: null_cloner_factory,
          section_repository: null_section_repository,
          directory_preparer: null_directory_preparer
        )

        expect(command.run('local')).to be_zero
      end
    end

    describe 'using template variables' do
      it 'includes them in the final site' do
        config = Config::Configuration.new(
          sections: [
            Config::SectionConfig.new(
              'repository' => {'name' => 'fantastic/my-variable-repo'},
              'directory' => 'var-repo'
            )
          ],
          book_repo: 'some/book',
          cred_repo: 'my-org/my-creds',
          public_host: 'example.com',
          template_variables: {'name' => 'Spartacus'}
        )
        bind_cmd(
          middleman_runner: real_middleman_runner,
          config_fetcher: double('config fetcher', fetch_config: config),
          file_system_accessor: real_fs_accessor,
          preprocessor: real_preprocessor
        ).run('remote')

        index_html = File.read File.join('final_app', 'public', 'var-repo', 'variable_index.html')
        expect(index_html).to include 'My variable name is Spartacus.'
      end
    end

    context 'when the verbose flag is not set' do
      it "sends a FilterStream out stream to Middleman" do
        middleman_runner = instance_double('Bookbinder::MiddlemanRunner')
        regular_stream = StringIO.new

        expect(middleman_runner).to receive(:run).with(
          "build --verbose",
          hash_including(streams: {
            out: instance_of(Streams::FilterStream),
            err: regular_stream,
            success: regular_stream,
          })) { failure }

        bind_cmd(middleman_runner: middleman_runner,
                 streams: { out: regular_stream,
                            err: regular_stream,
                            success: regular_stream }).
        run('local')
      end
    end

    context "when the verbose flag is set" do
      it "tells Middleman to run verbose, and sends the regular output stream to Middleman" do
        middleman_runner = instance_double('Bookbinder::MiddlemanRunner')
        regular_stream = StringIO.new

        expect(middleman_runner).to receive(:run).with(
          "build --verbose",
          hash_including(streams: {
            out: regular_stream,
            err: regular_stream,
            success: regular_stream,
          })) { failure }

        bind_cmd(middleman_runner: middleman_runner,
                 streams: { out: regular_stream,
                            err: regular_stream,
                            success: regular_stream }).
        run('local', true)
      end
    end
  end
end
