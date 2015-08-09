require 'tmpdir'
require_relative '../../../lib/bookbinder/config/configuration'
require_relative '../../../lib/bookbinder/middleman_runner'
require_relative '../../../lib/bookbinder/values/output_locations'
require_relative '../../../lib/bookbinder/values/section'
require_relative '../../helpers/middleman'

module Bookbinder
  describe MiddlemanRunner do
    include SpecHelperMethods

    class RecordingFs
      def write(to: nil, text: nil)
        @to = to
        @text = text
      end

      def received_to
        @to
      end

      def received_text_parsed
        YAML.load(@text)
      end
    end

    let(:fs) { RecordingFs.new }
    let(:middleman_runner) { MiddlemanRunner.new({out: StringIO.new}, fs) }

    let(:context_dir) { Pathname(Dir.mktmpdir) }
    let(:target_dir_path) { context_dir.join('output', 'master_middleman') }
    let(:template_variables) { {'anybody' => 'nobody'} }
    let(:production_host) { 'somehost' }
    let(:archive_menu) { {} }
    let(:verbose) { false }
    let(:sections) { [
        Section.new('path/to/repo', '', true, 'path/to', 'my/place/rocks', 'my_subnav_template'),
        Section.new('path/to/repo', '', true, 'path/to', 'fraggles/rock')
    ] }

    def run_middleman
      subnav_templates = {
          'my_place_rocks' => 'my_subnav_template',
          'fraggles_rock' => 'default'
      }

      output_locations = OutputLocations.new(
        context_dir: context_dir
      )

      target_dir_path.mkpath

      middleman_runner.run(
        output_locations,
        Config::Configuration.parse(
          'template_variables' => template_variables,
          'public_host' => production_host,
          'archive_menu' => archive_menu
        ),
        'local',
        verbose,
        subnav_templates)
    end

    it 'invokes Middleman in the requested directory' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      working_directory_path = nil
      allow(build_command).to receive(:invoke) { working_directory_path = `pwd`.strip }

      run_middleman

      expect(Pathname.new(working_directory_path).realpath).to eq(Pathname.new(target_dir_path).realpath)
    end

    it "stores bookbinder config for later consumption by our extension" do
      run_middleman
      expect(fs.received_to).to eq('bookbinder_config.yml')
      expect(fs.received_text_parsed).to eq(
        archive_menu: archive_menu,
        local_repo_dir: 'local',
        production_host: production_host,
        subnav_templates: { 'my_place_rocks' => 'my_subnav_template', 'fraggles_rock' => 'default' },
        template_variables: template_variables,
        workspace: context_dir.join('output/master_middleman/source'),
      )
    end

    it 'builds with middleman and passes the verbose parameter' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})
      expect(build_command).to receive(:invoke).with(:build, [], {:verbose => verbose})

      run_middleman
    end

    it 'sets the MM root for invocation' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      invocation_mm_root = nil
      allow(build_command).to receive(:invoke) { invocation_mm_root = ENV['MM_ROOT'] }

      run_middleman

      expect(invocation_mm_root).to eq(target_dir_path.to_s)
    end

    it 'resets the MM root in cleanup' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      original_mm_root = ENV['MM_ROOT']

      ENV['MM_ROOT'] = 'anything'

      allow(build_command).to receive(:invoke)

      run_middleman

      expect(ENV['MM_ROOT']).to eq('anything')

      ENV['MM_ROOT'] = original_mm_root
    end
  end
end
