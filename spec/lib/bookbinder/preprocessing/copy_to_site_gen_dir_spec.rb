require_relative '../../../../lib/bookbinder/preprocessing/copy_to_site_gen_dir'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../spec/helpers/nil_logger'

module Bookbinder
  module Preprocessing
    describe CopyToSiteGenDir do
      it "isn't 'applicable' to anything: designed to be used as a default" do
        preprocessor = CopyToSiteGenDir.new(double('filesystem'))
        expect(preprocessor).not_to be_applicable_to(Section.new)
      end

      it 'just copies sections from their cloned dir to the dir ready for site generation' do
        fs = double('filesystem')
        preprocessor = CopyToSiteGenDir.new(fs)
        output_locations = OutputLocations.new(context_dir: 'mycontextdir')

        Dir.mktmpdir do |tmpdir|
          Dir.mkdir(File.join(tmpdir, 'path1'))
          Dir.mkdir(File.join(tmpdir, 'path2'))

          sections = [
              Section.new(
                  File.join(tmpdir, 'path1'),
                  'myorg/myrepo',
                  copied = true,
                  'irrelevant/dest/dir',
                  'my/desired/dir'
              ),
              Section.new(
                  File.join(tmpdir, 'path2'),
                  'myorg/myrepo2',
                  copied = true,
                  'irrelevant/other/dest/dir',
                  desired_dir = nil
              )
          ]

          expect(fs).to receive(:copy_contents).with(
                            sections[0].path_to_repository,
                            output_locations.source_for_site_generator.join('my/desired/dir')
                        )
          expect(fs).to receive(:copy_contents).with(
                            sections[1].path_to_repository,
                            output_locations.source_for_site_generator.join('myrepo2')
                        )

          preprocessor.preprocess(sections, output_locations, 'unused', 'args')
        end
      end

      context 'if the source directory does not exist locally' do
        it 'does not copy the contents of that directory' do
          fs = double('filesystem')
          preprocessor = CopyToSiteGenDir.new(fs)
          output_locations = OutputLocations.new(context_dir: 'mycontextdir')
          sections = [
              Section.new(
                  '',
                  'myorg/myrepo',
                  copied = true,
                  'irrelevant/dest/dir',
                  'my/desired/dir'
              )
          ]

          expect(fs).to_not receive(:copy_contents)

          preprocessor.preprocess(sections, output_locations, 'unused', 'args')
        end

        it 'does not halt execution' do
          fs = double('filesystem')
          preprocessor = CopyToSiteGenDir.new(fs)
          output_locations = OutputLocations.new(context_dir: 'mycontextdir')

          Dir.mktmpdir do |tmpdir|
            Dir.mkdir(File.join(tmpdir, 'path2'))

            sections = [
                Section.new(
                    '',
                    'myorg/myrepo',
                    copied = true,
                    'irrelevant/dest/dir',
                    'my/desired/dir'
                ),
                Section.new(
                    File.join(tmpdir, 'path2'),
                    'myorg/myrepo2',
                    copied = true,
                    'irrelevant/other/dest/dir',
                    desired_dir = nil
                )
            ]

            expect(fs).to receive(:copy_contents).with(
                              sections[1].path_to_repository,
                              output_locations.source_for_site_generator.join('myrepo2')
                          )

            preprocessor.preprocess(sections, output_locations, 'unused', 'args')
          end
        end
      end
    end
  end
end
