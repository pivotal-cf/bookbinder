require_relative '../../../../lib/bookbinder/commands/watch'
require_relative '../../../../lib/bookbinder/commands/help'
require_relative '../../../../lib/bookbinder/middleman_runner'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Commands
    describe Watch do
      let(:unused_dependency) { Object.new }
      let(:untested_streams) { {} }
      let(:success) { double('process status', success?: true, exitstatus: 0) }

      it "has a command name" do
        watch = Watch.new({})
        expect(watch).to be_command_for("watch")
      end

      it "is compatible with the help command" do
        watch_cmd = Watch.new({})
        help = Commands::Help.new(unused_dependency, [watch_cmd])
        expect(help.usage_message).to include('watch')
      end

      it "prepares directories and then preprocesses fetched sections" do
        streams = {out: "foo"}
        directory_preparer = instance_double('BindComponents::DirectoryPreparer')
        output_locations = OutputLocations.new(context_dir: ".")
        preprocessor = instance_double('Preprocessing::Preprocessor')

        section_config = Config::SectionConfig.new({'directory' => 'foo'})
        config = Config::Configuration.new({book_repo: "some_book", sections: [section_config]})
        sections = [Section.new('fake/path', 'foo/bar'), Section.new('other/path', 'cat/dog')]
        section_repository = instance_double('Ingest::SectionRepository')
        cloner = instance_double('Ingest::LocalFileSystemCloner')

        allow(section_repository).to receive(:fetch).
          with(configured_sections: [section_config],
               destination_dir: Pathname("output/preprocessing/sections"),
               streams: streams,
               cloner: cloner) { sections }

        expect(directory_preparer).to receive(:prepare_directories).with(
            config,
            File.expand_path('../../../../', __dir__),
            output_locations,
            File.absolute_path('master_middleman')
        ).ordered

        expect(preprocessor).to receive(:preprocess).with(
            sections,
            output_locations,
            output_streams: streams
        ).ordered

        Watch.new(
          streams,
          middleman_runner: instance_double('MiddlemanRunner', run: success),
          output_locations: output_locations,
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: double('decorator', generate: config),
          file_system_accessor: instance_double('LocalFileSystemAccessor', file_exist?: false),
          preprocessor: preprocessor,
          cloner: cloner,
          section_repository: section_repository,
          directory_preparer: directory_preparer
        ).run([])
      end

      it "copies the redirect file if present before running middleman" do
        fs = instance_double("LocalFileSystemAccessor")
        allow(fs).to receive(:file_exist?).with("redirects.rb") { true }
        runner = instance_double('MiddlemanRunner', run: success)
        config = Config::Configuration.new({})

        expect(fs).to receive(:copy).with("redirects.rb", Pathname("foo")).ordered
        expect(runner).to receive(:run).ordered

        Watch.new(
          untested_streams,
          middleman_runner: runner,
          output_locations: OutputLocations.new(context_dir: ".", final_app_dir: "foo"),
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: double('decorator', generate: config),
          file_system_accessor: fs,
          preprocessor: instance_double('Preprocessing::Preprocessor', preprocess: nil),
          section_repository: instance_double('Ingest::SectionRepository', fetch: []),
          directory_preparer: instance_double('BindComponents::DirectoryPreparer', prepare_directories: nil)
        ).run([])
      end

      it "runs the middleman server" do
        output_locations = OutputLocations.new(context_dir: ".")
        runner = instance_double('MiddlemanRunner', run: success)
        config = Config::Configuration.new({book_repo: "best_book"})
        section = Section.new('fake/path', 'foo/bar')
        streams = {out: "foo"}
        config_decorator = double('decorator')
        decorated_config = Config::Configuration.new(book_repo: "best_book", public_host: "a_host")
        allow(config_decorator).to receive(:generate).with(config, [section]) { decorated_config }

        expect(runner).to receive(:run).with("server --force-polling --latency=5.0",
          output_locations: output_locations,
          config:           decorated_config,
          local_repo_dir:   File.expand_path(".."),
          streams:          streams,
          subnavs:          section.subnav)

        Watch.new(
          streams,
          middleman_runner: runner,
          output_locations: output_locations,
          config_fetcher: instance_double('Bookbinder::Config::Fetcher', fetch_config: config),
          config_decorator: config_decorator,
          file_system_accessor: instance_double('LocalFileSystemAccessor', file_exist?: false),
          preprocessor: instance_double('Preprocessing::Preprocessor', preprocess: nil),
          cloner: instance_double('Ingest::LocalFileSystemCloner'),
          section_repository: instance_double('Ingest::SectionRepository', fetch: [section]),
          directory_preparer: instance_double('BindComponents::DirectoryPreparer', prepare_directories: nil)
        ).run([])
      end
    end
  end
end
