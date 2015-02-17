require_relative '../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe DitaHtmlToMiddlemanFormatter do

    use_fixture_repo('my-dita-output-repo')

    def dita_html_to_middleman_formatter
      file_accessor = LocalFileSystemAccessor.new
      DitaHtmlToMiddlemanFormatter.new(file_accessor)
    end

    it 'creates an ERB file with the same name for every HTML file in the directory' do
      Dir.mktmpdir do |tmpdir|
        expected_filepath = File.expand_path File.join tmpdir, 'output.html.erb'
        expected_nested_filepath = File.expand_path File.join tmpdir, 'nested-dir/nested-output.html.erb'

        dita_html_to_middleman_formatter.format(File.expand_path('.'), tmpdir)
        expect(File.exist? expected_filepath).to eq true
        expect(File.exist? expected_nested_filepath).to eq true
      end
    end

    it 'inserts the body contents of an HTML file into the ERB file' do
      Dir.mktmpdir do |tmpdir|
        expected_filepath = File.expand_path File.join(tmpdir, 'output.html.erb')

        dita_html_to_middleman_formatter.format(File.expand_path('.'), tmpdir)
        expect(File.read expected_filepath).to include '<h1 class="title topictitle1">GemFire XD Features and Benefits</h1>'
      end
    end

    it 'adds YAML frontmatter to the ERB file to allow access to the <head> attributes' do
      Dir.mktmpdir do |tmpdir|
        expected_filepath = File.expand_path File.join(tmpdir, 'output.html.erb')
        expected_frontmatter = "---\ntitle: \"GemFire XD's Features and Benefits (\\\"Features\\\")\"\ndita: true\n---"

        dita_html_to_middleman_formatter.format(File.expand_path('.'), tmpdir)
        expect(File.read expected_filepath).to include expected_frontmatter
      end
    end
  end
end