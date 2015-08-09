require 'tmpdir'
require_relative '../../../lib/bookbinder/config/configuration'
require_relative '../../../lib/bookbinder/middleman_runner'
require_relative '../../../lib/bookbinder/sheller'
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
    let(:sheller) { instance_double('Bookbinder::Sheller') }
    let(:streams) { { out: StringIO.new, err: StringIO.new } }
    let(:middleman_runner) { MiddlemanRunner.new(streams, fs, sheller) }

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
      working_directory_path = nil
      allow(sheller).to receive(:run_command) { working_directory_path = `pwd`.strip }
      run_middleman
      expect(Pathname.new(working_directory_path).realpath).to eq(Pathname.new(target_dir_path).realpath)
    end

    it "stores bookbinder config for later consumption by our extension" do
      allow(sheller).to receive(:run_command)
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

    context "when verbose output is requested" do
      let(:verbose) { true }
      it 'builds with middleman in verbose mode' do
        expect(sheller).to receive(:run_command).with(anything,
                                                      "middleman build --verbose",
                                                      streams)
        run_middleman
      end
    end

    context "when verbose output is not requested" do
      let(:verbose) { false }
      it 'builds with middleman in no verbose mode' do
        expect(sheller).to receive(:run_command).with(anything,
                                                      "middleman build --no-verbose",
                                                      streams)
        run_middleman
      end
    end

    it 'sets the MM root for invocation' do
        expect(sheller).to receive(:run_command).with({'MM_ROOT' => context_dir.join('output/master_middleman').to_s},
                                                      anything,
                                                      anything)
        run_middleman
    end

    it "raises an exception if Middleman gives a nonzero exit code" do

    end
  end
end
