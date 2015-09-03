require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/preprocessing/link_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../spec/helpers/nil_logger'

module Bookbinder
  module Preprocessing
    describe LinkToSiteGenDir do
      it 'links sections from their cloned dir to the dir ready for site generation' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        preprocessor = LinkToSiteGenDir.new(fs)
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

        expect(fs).to receive(:link_creating_intermediate_dirs).with(
          sections[0].path_to_repository,
          output_locations.source_for_site_generator.join('my/desired/dir')
        )
        expect(fs).to receive(:link_creating_intermediate_dirs).with(
          sections[1].path_to_repository,
          output_locations.source_for_site_generator.join('myrepo2')
        )

        preprocessor.preprocess(sections, output_locations, 'unused', 'args')
      end

      it "is applicable to sections whose source dir exists" do
        fs = double('fs')

        allow(fs).to receive(:file_exist?).with(Pathname('foo')) { true }

        preprocessor = LinkToSiteGenDir.new(fs)
        expect(preprocessor).to be_applicable_to(Section.new('foo'))
      end

      it "isn't applicable to sections whose source dir doesn't exist" do
        fs = double('fs')

        allow(fs).to receive(:file_exist?).with(Pathname('foo')) { false }

        preprocessor = LinkToSiteGenDir.new(fs)
        expect(preprocessor).not_to be_applicable_to(Section.new('foo'))
      end
    end
  end
end
