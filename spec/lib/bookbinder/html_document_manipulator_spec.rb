require_relative '../../../lib/bookbinder/html_document_manipulator'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe HtmlDocumentManipulator do

    def html_document_manipulator
      HtmlDocumentManipulator.new
    end

    describe 'setting an attribute' do
      it 'returns a copy of the document with attribute set to the specified value' do
        document_body = '<div class="wrapper"><div class="selector"></div></div>'
        selector = 'div.selector'
        attribute = 'data-name'
        new_value = 'this is a name'

        expect(html_document_manipulator.set_attribute(document: document_body,
                                                       selector: selector,
                                                       attribute: attribute,
                                                       value: new_value)
        ).to eq '<div class="wrapper"><div class="selector" data-name="this is a name"></div></div>'
      end
    end

    describe 'adding a class' do
      it 'returns a copy of the document with the given class added to the element' do
        expect(html_document_manipulator.add_class(
            document: '<div class="wrapper"><div class="selector"></div></div>',
            selector: 'div.selector',
            classname: 'classier')
        ).to eq '<div class="wrapper"><div class="selector classier"></div></div>'
      end
    end

    describe 'reading from a particular part of a file' do
      it 'returns the desired content as a string' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          File.write(filepath, '<body><header><p>this is some text</p></header></body>')
          doc = File.read filepath

          expect(html_document_manipulator.read_html_in_tag(document: doc,
                                                            tag: 'body')).
              to eq '<header><p>this is some text</p></header>'
        end
      end

      context 'when the files are multiline' do
        use_fixture_repo('my-dita-output-repo')

        it 'returns the correct selection' do
          filepath = File.expand_path './output.html'
          doc = File.read filepath

          expect(html_document_manipulator.read_html_in_tag(document: doc,
                                                            tag: 'title')).
              to eq 'GemFire XD\'s Features and Benefits ("Features")'
        end
      end

      context 'when the file does not contain the marker' do
        it 'returns an empty string' do
          Dir.mktmpdir do |tmpdir|
            filepath = File.join tmpdir, 'filename.txt'
            File.write(filepath, '<head><body>this is some text</body></head>')
            doc = File.read filepath

            expect(html_document_manipulator.read_html_in_tag(document: doc,
                                                              tag: 'nonexistent')).
                to eq ''
          end
        end
      end
    end
  end
end

