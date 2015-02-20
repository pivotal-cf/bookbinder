require_relative '../../../lib/bookbinder/dita_html_to_middleman_formatter'
require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../lib/bookbinder/dita_section'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe DitaHtmlToMiddlemanFormatter do

    use_fixture_repo('my-dita-output-repo')

    def dita_html_to_middleman_formatter
      file_accessor = LocalFileSystemAccessor.new
      null_subnav_formatter = double('null_subnav_formatter')
      null_document_parser = double('null_document_parser')
      DitaHtmlToMiddlemanFormatter.new(file_accessor,
                                       null_subnav_formatter,
                                       null_document_parser)
    end

    describe 'formatting HTML from DITA' do
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

    describe 'formatting subnavs created from TOC-js' do
      it 'writes a subnav for each DITA-section to the subnavs directory using a provided subnav template' do
        fs_accessor = double('fs_accessor', read: nil)
        subnav_formatter = double('subnav_formatter')
        document_parser = double('doc_parser')
        dita_formatter = DitaHtmlToMiddlemanFormatter.new(fs_accessor, subnav_formatter, document_parser)

        dita_sections = [DitaSection.new('path/to/local/repo',
                                         'relative/path/to/ditamap',
                                         'org/my_dita_section',
                                         nil,
                                         'my_dita_section')]

        expect(fs_accessor).to receive(:read).
                                   with('path/to/html_from_dita_path/my_dita_section/index.html').
                                   and_return('some text')

        allow(document_parser).to receive(:insert_text_after_selector).and_return('<div class=nav-content>this is formatted</div>')

        expect(subnav_formatter).to receive(:format).with('some text', 'my_dita_section').and_return('this is formatted')

        expect(fs_accessor).to receive(:write).
                                   with(text: '<div class=nav-content>this is formatted</div>',
                                        to: File.join('subnav_destination_dir', 'my_dita_section_subnav.erb'))

        dita_formatter.format_subnavs(dita_sections,
                                      'path/to/html_from_dita_path',
                                      'subnav_destination_dir',
                                      '<div class=nav-content></div>')
      end
    end
  end
end