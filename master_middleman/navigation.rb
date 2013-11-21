# mostly from https://github.com/multiscan/middleman-navigation but modified slightly
module Navigation
  class << self
    def registered(app)
      app.helpers HelperMethods
    end

    alias :included :registered
  end

  class Middleman::Sitemap::Resource
    def nonav?
      self.data && self.data[:nonav]
    end
    def hidden?
      self.data && self.data['hidden'] || File.basename(self.path, ".html")[-1]=="_" || File.basename(self.path, ".html")[0]=="_" || File.basename(File.dirname(self.path))[0]=="_"
    end
    def weight
      self.data && self.data['weight'] || 0
    end
  end

  module HelperMethods
    def make_breadcrumb(page)
      text = page.data.title
      return nil if !text

      if page == current_page
        css_class = 'active'
        link = content_tag :span, text
      else
        link = link_to(text, '/' + page.path)
      end
      return content_tag :li, link, :class => css_class
    end

    def breadcrumbs
      return if current_page.parent.nil?
      page = current_page
      breadcrumbs = Array.new
      breadcrumbs << make_breadcrumb(page)
      while page = page.parent
        breadcrumb = make_breadcrumb(page)
        breadcrumbs << breadcrumb if breadcrumb
      end
      return content_tag :ul, breadcrumbs.reverse.join(' '), class: 'breadcrumbs'
    end
  end
end

::Middleman::Extensions.register(:navigation, Navigation) 
