require 'date'
require_relative 'archive_drop_down_menu'
require_relative 'quicklinks_renderer'

I18n.enforce_available_locales = false

module Bookbinder
  module Navigation
    class << self
      def registered(app)
        app.helpers HelperMethods
      end

      alias :included :registered
    end

    module HelperMethods

      def yield_for_code_snippet(from: nil, at: nil)
        git_accessor = config[:git_accessor]
        cloner = config[:cloner]
        attributes = {'repository' => {'name' => from}}
        workspace = config[:workspace]
        code_example_reader = CodeExampleReader.new(out: $stdout)

        working_copy = cloner.call(source_repo_name: from,
                                   source_ref: 'master',
                                   destination_parent_dir: workspace)

        snippet, language = code_example_reader.get_snippet_and_language_at(at, working_copy)

        delimiter = '```'

        snippet.prepend("#{delimiter}#{language}\n").concat("\n#{delimiter}")
      end

      def yield_for_subnav
        partial "subnavs/#{subnav_template_name}"
      end

      def yield_for_archive_drop_down_menu
        menu = ArchiveDropDownMenu.new(
          config[:archive_menu],
          current_path: current_page.path
        )

        partial 'archive_menus/default', locals: { menu_title: menu.title,
                                                   dropdown_links: menu.dropdown_links }
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
        quicklinks_renderer = QuicklinksRenderer.new(vars)
        Redcarpet::Markdown.new(quicklinks_renderer).render(page_src)
      end

      private

      def subnav_template_name
        template_key = decreasingly_specific_namespaces.detect { |ns|
          config[:subnav_templates].has_key?(ns)
        }
        config[:subnav_templates][template_key] || 'default'
      end

      def decreasingly_specific_namespaces
        page_classes(numeric_prefix: numeric_class_prefix).
          split(' ').reverse.drop(1).
          map {|ns| ns.sub(/^#{numeric_class_prefix}/, '')}
      end

      def numeric_class_prefix
        'NUMERIC_CLASS_PREFIX'
      end

      def add_ancestors_of(page, ancestors)
        if page
          add_ancestors_of(page.parent, ancestors + [page])
        else
          ancestors
        end
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
end
::Middleman::Extensions.register(:navigation, Bookbinder::Navigation)
