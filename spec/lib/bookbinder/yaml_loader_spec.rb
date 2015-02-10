require 'tmpdir'
require_relative '../../../lib/bookbinder/yaml_loader'

module Bookbinder
  describe YAMLLoader do
    it "returns an empty hash when given a blank YAML file to parse" do
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)
        File.write(dir.join('foo.yml'), "---\n")
        expect(
          YAMLLoader.new.load(dir.join('foo.yml'))
        ).not_to have_key('foo')
      end
    end
  end
end
