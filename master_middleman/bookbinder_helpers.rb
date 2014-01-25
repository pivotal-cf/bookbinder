# mostly from https://github.com/multiscan/middleman-navigation but modified slightly

module Navigation
  class << self
    def registered(app)
      app.helpers HelperMethods
    end

    alias :included :registered
  end

  module HelperMethods

    def yield_for_subnav
      ignore_list = ['index', 'x404']
      topic = page_classes.split(' ')[0].chomp
      partial "subnavs/#{topic}" unless ignore_list.include? topic
    end

    def breadcrumbs
      page_chain = add_ancestors_of(current_page, [])
      breadcrumbs = page_chain.map do |page|
        make_breadcrumb(page, page == current_page)
      end.compact
      return if breadcrumbs.size < 2
      return content_tag :ul, breadcrumbs.reverse.join(' '), class: 'breadcrumbs'
    end

    def vars
      OpenStruct.new config[:template_variables]
    end

    def quick_links
      page_src = File.read(current_page.source_file)
      sections = page_src.scan /\n\#{2,3}[^#]+\#{2,3}\n/

      markdown = ''

      sections.each do |s|

        next if s.match(/id=['"](.+)['"]/).nil? or s.match(/<\/a>([^#.]+)\#{2,3}/).nil?

        anchor_name = s.match(/id=['"](.+)['"]/)[1]
        title = s.match(/<\/a>([^#.]+)\#{2,3}/)[1].strip!
        indent = (s.count('#') / 2) - 2

        markdown << '  ' * indent
        markdown << "* [#{title}](##{anchor_name})\n"

      end

      md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      result = md.render(markdown)
      result.empty? ? '' : "<div class=\"quick-links\">#{result}</div>"
    end

    private

    def add_ancestors_of(page, ancestors)
      return ancestors if !page
      add_ancestors_of(page.parent, ancestors << page)
    end

    def make_breadcrumb(page, is_current_page)
      return nil unless (text = page.data.breadcrumb || page.data.title)
      if is_current_page
        css_class = 'active'
        link = content_tag :span, text
      else
        link = link_to(text, '/' + page.path)
      end
      content_tag :li, link, :class => css_class
    end

  end
end

::Middleman::Extensions.register(:navigation, Navigation)
