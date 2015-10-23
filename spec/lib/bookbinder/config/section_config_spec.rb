require_relative '../../../../lib/bookbinder/config/section_config'

module Bookbinder
  module Config
    describe SectionConfig do
      it "can return the preprocessor config" do
        expect(
          SectionConfig.new('preprocessor_config' => {
            'some' => 'data',
            '4' => 'u'
          }).preprocessor_config
        ).to eq('some' => 'data', '4' => 'u')
      end

      it "returns an empty preprocessor config if not defined" do
        expect(SectionConfig.new({}).preprocessor_config).to eq({})
      end

      it "can return the provided subnav template" do
        expect(SectionConfig.new('subnav_template' => 'mysubnav').subnav_template).
          to eq('mysubnav')
      end

      it "can return the provided subnav name" do
        expect(SectionConfig.new('subnav_name' => 'mygeneratedsubnav').subnav_name).
          to eq('mygeneratedsubnav')
      end

      it "can return the desired directory name" do
        expect(SectionConfig.new('directory' => 'mygreatdir').desired_directory_name).
          to eq('mygreatdir')
      end

      it "can return the repo name" do
        expect(SectionConfig.new('repository' => {'name' => 'foo/bar'}).repo_name).
          to eq('foo/bar')
      end

      it "can return the path to a directory in repo" do
        expect(SectionConfig.new('repository' => {'name' => 'foo/bar', 'at_path' => 'some/nested/dir'}).at_repo_path).
          to eq('some/nested/dir')
      end

      it "produces a URL from a name" do
        expect(SectionConfig.new('repository' => {'name' => 'foo/bar'}).repo_url).
          to eq('git@github.com:foo/bar')
      end

      describe "checkout ref" do
        it "returns any ref provided" do
          expect(SectionConfig.new('repository' => {'ref' => 'foobar'}).repo_ref).
            to eq('foobar')
        end

        it "defaults to master if ref not provided" do
          expect(SectionConfig.new('repository' => {'name' => 'unimportant'}).repo_ref).to eq('master')
        end

        it "defaults to master if ref is nil" do
          expect(SectionConfig.new('repository' => {'ref' => nil}).repo_ref).to eq('master')
        end
      end

      it "can return dependent sections" do
        section_config = SectionConfig.new(
          {
            'repository' => {'name' => 'foo/section'},
            'directory' => 'parent_dir',
            'dependent_sections' => [
              {
                'repository' => {'name' => 'my/first-dependent-repo'},
                'directory' => 'first_dependent_dir'
              },
              {
                'repository' => {'name' => 'my/second-dependent-repo'},
                'directory' => 'second_dependent_dir'
              }
            ]
          }
        )

        expect(section_config.dependent_sections).to eq(
            [
              SectionConfig.new(
                {
                  'repository' => {'name' => 'my/first-dependent-repo'},
                  'directory' => 'first_dependent_dir'
                }
              ),
              SectionConfig.new(
              {
                'repository' => {'name' => 'my/second-dependent-repo'},
                'directory' => 'second_dependent_dir'
              }
            )
          ]
        )
      end

      it "is equal to another instance with same config" do
        expect(SectionConfig.new('repository' => {'ref' => 'foo'})).
          to eq(SectionConfig.new('repository' => {'ref' => 'foo'}))
      end

      it "isn't equal to another instance with different config" do
        expect(SectionConfig.new('repository' => {'ref' => 'foo'})).
          not_to eq(SectionConfig.new('repository' => {'ref' => 'bar'}))
      end
    end
  end
end
