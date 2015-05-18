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

      it "can return the provided subnav template" do
        expect(SectionConfig.new('subnav_template' => 'mysubnav').subnav_template).
          to eq('mysubnav')
      end

      it "can return the desired directory name" do
        expect(SectionConfig.new('directory' => 'mygreatdir').desired_directory_name).
          to eq('mygreatdir')
      end

      it "can return the repo name" do
        expect(SectionConfig.new('repository' => {'name' => 'foo/bar'}).repo_name).
          to eq('foo/bar')
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
