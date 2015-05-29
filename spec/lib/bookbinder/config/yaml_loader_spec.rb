require 'tmpdir'
require_relative '../../../../lib/bookbinder/config/yaml_loader'

module Bookbinder
  module Config
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

      describe "extracting a single key from a given file" do
        context "when the file exists and key is present" do
          it "returns the value" do
            Dir.mktmpdir do |dir|
              dir = Pathname(dir)
              File.write(dir.join('foo.yml'), "---\nfoo: bar")
              expect(
                YAMLLoader.new.load_key(dir.join('foo.yml'), 'foo')
              ).to eq('bar')
            end
          end
        end

        context "when the file exists but key isn't present" do
          it "returns nil" do
            Dir.mktmpdir do |dir|
              dir = Pathname(dir)
              File.write(dir.join('foo.yml'), "---\nfoo: bar")
              expect(
                YAMLLoader.new.load_key(dir.join('foo.yml'), 'baz')
              ).to be_nil
            end
          end
        end

        context "when the file doesn't exist" do
          it "returns nil (asymmetrical with non-key version...revisit)" do
            expect(
              YAMLLoader.new.load_key('non-existent.yml', 'baz')
            ).to be_nil
          end
        end

        context "when the file is a valid but empty YAML file" do
          it "returns nil" do
            Dir.mktmpdir do |dir|
              dir = Pathname(dir)
              File.write(dir.join('foo.yml'), "---\n")
              expect(
                YAMLLoader.new.load_key(dir.join('foo.yml'), 'baz')
              ).to be_nil
            end
          end
        end

        context "when the file is invalid" do
          it "raises an exception" do
            Dir.mktmpdir do |dir|
              dir = Pathname(dir)
              File.write(dir.join('foo.yml'), "{")
              expect {
                YAMLLoader.new.load_key(dir.join('foo.yml'), 'baz')
              }.to raise_error(InvalidSyntaxError)
            end
          end
        end
      end
    end
  end
end
