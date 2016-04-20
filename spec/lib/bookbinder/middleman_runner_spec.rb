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
    let(:middleman_runner) { MiddlemanRunner.new(fs, sheller) }

    let(:context_dir) { Pathname(Dir.mktmpdir) }
    let(:target_dir_path) { context_dir.join('output', 'master_middleman') }
    let(:template_variables) { {'anybody' => 'nobody'} }
    let(:production_host) { 'somehost' }
    let(:archive_menu) { {} }
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
        "potato",
        streams: streams,
        output_locations: output_locations,
        config: Config::Configuration.parse(
          'feedback_enabled' => true,
          'repo_link_enabled' => true,
          'template_variables' => template_variables,
          'public_host' => production_host,
          'archive_menu' => archive_menu,
          'repo_links' => {
            'some_dir' => {
              'repo' => 'some repo link',
              'ref' => 'some ref',
              'at_path' => 'whatever stuff'
            }
          },
        ),
        local_repo_dir: 'local',
        subnavs: subnav_templates)
    end

    it "invokes Middleman in the requested directory" do
      working_directory_path = nil
      allow(sheller).to receive(:run_command) { working_directory_path = `pwd`.strip }
      run_middleman
      expect(Pathname.new(working_directory_path).realpath).to eq(Pathname.new(target_dir_path).realpath)
    end

    it "returns the sheller's return value" do
      process_status = double('process status')
      allow(sheller).to receive(:run_command) { process_status }
      expect(run_middleman).to eq(process_status)
    end

    it "stores bookbinder config for later consumption by our extension" do
      allow(sheller).to receive(:run_command)
      run_middleman
      expect(fs.received_to).to eq('bookbinder_config.yml')
      expect(fs.received_text_parsed).to eq(
        archive_menu: archive_menu,
        local_repo_dir: 'local',
        product_info: nil,
        production_host: production_host,
        subnav_templates: { 'my_place_rocks' => 'my_subnav_template', 'fraggles_rock' => 'default' },
        template_variables: template_variables,
        workspace: context_dir.join('output/master_middleman/source'),
        feedback_enabled: true,
        repo_link_enabled: true,
        repo_links: {
          'some_dir' =>
          {'repo' => 'some repo link',
            'ref' => 'some ref',
            'at_path' => 'whatever stuff'
          }
        },
        elastic_search: false,
      )
    end

    it "sends the command to the sheller" do
      expect(sheller).to receive(:run_command).with(anything, "middleman potato", anything)
      run_middleman
    end

    it "sets the MM root for invocation" do
      expect(sheller).to receive(:run_command).with({'MM_ROOT' => context_dir.join('output/master_middleman').to_s},
                                                    anything,
                                                    anything)
      run_middleman
    end

    it "passes the streams through to the sheller" do
      expect(sheller).to receive(:run_command).with(anything, anything, streams)
      run_middleman
    end
  end
end
