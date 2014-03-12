# mostly from https://github.com/multiscan/middleman-navigation but modified slightly
require_relative 'quicklinks_renderer'

I18n.enforce_available_locales = false

module Navigation
  class << self
    def registered(app)
      app.helpers HelperMethods
    end

    alias :included :registered
  end

  module HelperMethods

    def yield_for_code_snippet(from: nil, at: nil)
      repo = CodeRepo.get_instance from, config[:local_repo_dir]
      snippet, language = repo.get_snippet_and_language_at(at)
      delimiter = '```'

      snippet.prepend("#{delimiter}#{language}\n").concat("\n#{delimiter}")
    end

    def yield_for_subnav
      namespaces = decreasingly_specific_namespaces

      template = namespaces.map do |namespace|
        config[:subnav_templates][namespace]
      end.compact.pop || 'default'

      partial "subnavs/#{template}"
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
      Redcarpet::Markdown.new(QuicklinksRenderer).render(page_src)
    end

    private

    def decreasingly_specific_namespaces
      page_classes.split(' ')[0...-1].reverse
    end

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
