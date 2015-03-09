require 'nokogiri'
require_relative '../helpers/environment_setups'
require_relative '../helpers/application'
require_relative '../helpers/book_fixture'

module Bookbinder
  describe "binding a book with local DITA sections" do

    around_in_dita_ot_env(ENV)

    it "processes the DITA into HTML in the output dir" do
      application = Application.new
      dita_book = BookFixture.new('dita-book')

      application.bind_book_from_local(dita_book) do
        expect(dita_book.has_html_section_for('dita-section-one')).to eq true
      end
    end
  end
end


