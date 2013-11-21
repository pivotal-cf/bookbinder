# mostly from https://github.com/multiscan/middleman-navigation but modified slightly
module Navigation
  class << self
    def registered(app)
      app.helpers HelperMethods
    end

    alias :included :registered
  end

  module HelperMethods

    def breadcrumbs
      return if current_page.parent.nil?
      page = current_page
      breadcrumbs = Array.new

      # TODO: test logic about current page
      breadcrumbs << make_breadcrumb(page, page == current_page)
      while page = page.parent
        breadcrumb = make_breadcrumb(page, page == current_page)
        breadcrumbs << breadcrumb if breadcrumb
      end
      return content_tag :ul, breadcrumbs.reverse.join(' '), class: 'breadcrumbs'
    end

    private

    def make_breadcrumb(page, is_current_page)
      text = page.data.title
      return nil if !text

      if is_current_page
        css_class = 'active'
        link = content_tag :span, text
      else
        link = link_to(text, '/' + page.path)
      end
      return content_tag :li, link, :class => css_class
    end

  end
end

::Middleman::Extensions.register(:navigation, Navigation) 
