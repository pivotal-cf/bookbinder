module Bookbinder
  class BookFixture
    attr_reader :name

    def initialize(book_name)
      @name = book_name
    end

    def has_html_section_for(dita_section)
      path = Pathname("./final_app/public/#{dita_section}/index.html")
      frag = Nokogiri::HTML.fragment(path.read)
      frag.css("ul>li>a").present?
    end

  end
end