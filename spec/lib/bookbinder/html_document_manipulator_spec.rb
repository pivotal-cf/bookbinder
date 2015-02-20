require_relative '../../../lib/bookbinder/html_document_manipulator'

module Bookbinder
  describe HtmlDocumentManipulator do
    it 'inserts text into a document at a given marker' do
      html_document_manipulator = HtmlDocumentManipulator.new

      text_to_insert = '<div>I am inside</div>'
      document_body = '<div class="wrapper"><div class="selector"></div></div>'
      selector = 'div.selector'

      expect(html_document_manipulator.insert_text_after_selector(text: text_to_insert,
                                                                  document: document_body,
                                                                  selector: selector)).
          to eq '<div class="wrapper"><div class="selector"><div>I am inside</div></div></div>'
    end
  end
end

