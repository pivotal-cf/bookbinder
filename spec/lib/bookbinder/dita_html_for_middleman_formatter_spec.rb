require_relative '../../../lib/bookbinder/dita_html_for_middleman_formatter'
require_relative '../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../lib/bookbinder/html_document_manipulator'

module Bookbinder
  describe DitaHtmlForMiddlemanFormatter do
    let(:fs) { instance_double('Bookbinder::LocalFilesystemAccessor', find_files_with_ext: ['thing.html'], read: html_text) }
    let(:html_doc_manipulator) { instance_double('Bookbinder::HtmlDocumentManipulator') }
    let(:html_text) { 'some text' }

    describe 'formatting HTML from DITA' do
      it 'creates a properly formatted ERB file with the same name for every HTML file in the directory' do
        allow(html_doc_manipulator).to receive(:read_html_in_tag).with(document: 'some text', tag: 'title') { 'title "text"' }
        allow(html_doc_manipulator).to receive(:read_html_in_tag).
            with(document: 'some text', tag: 'body') { 'body text &lt;% tag %&gt; &lt;\% tag to not convert %&gt;' }

        allow(fs).to receive(:relative_path_from).with('src/folder', 'thing.html') { 'rel/path/file.html' }

        frontmatter = "---\ntitle: \"title \\\"text\\\"\"\ndita: true\n---\n"
        expected_html = frontmatter + 'body text <% tag %> &lt;% tag to not convert %>'

        expect(fs).to receive(:write).with(to: 'dest/folder/rel/path/file.html.erb', text: expected_html)

        DitaHtmlForMiddlemanFormatter.new(fs, html_doc_manipulator).format_html('src/folder', 'dest/folder')
      end
    end
  end
end
