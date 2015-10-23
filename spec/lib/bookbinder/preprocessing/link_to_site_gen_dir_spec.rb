require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/json_from_markdown_toc'
require_relative '../../../../lib/bookbinder/preprocessing/link_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../spec/helpers/nil_logger'

module Bookbinder
  module Preprocessing
    describe LinkToSiteGenDir do
      let(:unused_dependency) { double('something we do not use').as_null_object }

      it 'links sections from their cloned dir to the dir ready for site generation' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        preprocessor = LinkToSiteGenDir.new(fs, unused_dependency)
        output_locations = OutputLocations.new(context_dir: 'mycontextdir')

        sections = [
          Section.new(
            'path1',
            'myorg/myrepo',
            'my/desired/dir'
          ),
          Section.new(
            'path2',
            'myorg/myrepo2',
            desired_dir = nil
          )
        ]

        config = Config::Configuration.parse({})

        expect(fs).to receive(:link_creating_intermediate_dirs).with(
          sections[0].path_to_repo_dir,
          output_locations.source_for_site_generator.join('my/desired/dir')
        )
        expect(fs).to receive(:link_creating_intermediate_dirs).with(
          sections[1].path_to_repo_dir,
          output_locations.source_for_site_generator.join('myrepo2')
        )

        preprocessor.preprocess(sections, output_locations, config: config, random_key: 'annie-dog')
      end

      it "is applicable to sections whose source dir exists" do
        fs = double('fs')

        allow(fs).to receive(:file_exist?).with(Pathname('foo')) { true }

        preprocessor = LinkToSiteGenDir.new(fs, unused_dependency)
        expect(preprocessor).to be_applicable_to(Section.new('foo'))
      end

      it "isn't applicable to sections whose source dir doesn't exist" do
        fs = double('fs')

        allow(fs).to receive(:file_exist?).with(Pathname('foo')) { false }

        preprocessor = LinkToSiteGenDir.new(fs, unused_dependency)
        expect(preprocessor).not_to be_applicable_to(Section.new('foo'))
      end

      it 'calls generate subnav for each subnav in the config' do
        fs = double('fs')
        subnav_generator_factory = instance_double('Bookbinder::Subnav::SubnavGeneratorFactory')
        generator = instance_double('Bookbinder::Subnav::SubnavGenerator')

        output_locations = OutputLocations.new(context_dir: 'mycontextdir')
        config = Config::Configuration.parse({
            'subnavs' => [
              {'name' => 'subnav-group',
                'topics' => ['The best topic']
              }
            ]
          }
        )

        expect(subnav_generator_factory).to receive(:produce).with(instance_of(Subnav::JsonFromMarkdownToc)) { generator }
        expect(generator).to receive(:generate).with(config.subnavs[0])

        preprocessor = LinkToSiteGenDir.new(fs, subnav_generator_factory)
        preprocessor.preprocess([], output_locations, config: config, output_streams: {})
      end
    end
  end
end
