require_relative '../../../lib/bookbinder/html_document_manipulator'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe HtmlDocumentManipulator do

    def html_document_manipulator
      HtmlDocumentManipulator.new
    end

    it 'inserts text into a document at a given marker' do
      text_to_insert = '<div>I am inside</div>'
      document_body = '<div class="wrapper"><div class="selector"></div></div>'
      selector = 'div.selector'

      expect(html_document_manipulator.insert_text_after_selector(text: text_to_insert,
                                                                  document: document_body,
                                                                  selector: selector)).
          to eq '<div class="wrapper"><div class="selector"><div>I am inside</div></div></div>'
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

