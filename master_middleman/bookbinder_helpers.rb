require 'bookbinder/code_example_reader'
require 'bookbinder/ingest/cloner_factory'
require 'bookbinder/ingest/git_accessor'
require 'bookbinder/local_filesystem_accessor'
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
        cloner_factory = Ingest::ClonerFactory.new({out: $stdout},
                                                   LocalFilesystemAccessor.new,
                                                   Ingest::GitAccessor.new)

        cloner = cloner_factory.produce(config[:local_repo_dir])
        code_example_reader = CodeExampleReader.new({out: $stdout},
                                                    LocalFilesystemAccessor.new)
        working_copy = cloner.call(source_repo_name: from,
                                   source_ref: 'master',
                                   destination_parent_dir: config[:workspace])

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
        unless menu.empty?
          partial 'archive_menus/default', locals: { menu_title: menu.title,
                                                     dropdown_links: menu.dropdown_links }
        end
      end

      def exclude_feedback
        current_page.add_metadata({page: {feedback_disabled: true}})
      end

      def yield_for_feedback
        partial 'layouts/feedback' if config[:feedback_enabled] && !current_page.metadata[:page][:feedback_disabled]
      end

      def exclude_repo_link
        current_page.add_metadata({page: {repo_link_disabled: true}})
      end

      def render_repo_link(include_environments: [])
        if config[:repo_link_enabled] && repo_url && !current_page.metadata[:page][:repo_link_disabled]
          id = 'repo-link'
          whitelisted_envs = include_environments.join(" ")
          default_display = 'display: none;'
          display_text = 'View the source for this page in GitHub'

          "<a id='#{id}' data-whitelist='#{whitelisted_envs}' style='#{default_display}' href='#{repo_url}'>#{display_text}</a>"
        end
      end

      def mermaid_diagram(&blk)
        escaped_text = capture(&blk).gsub('-','\-')

        @_out_buf.concat "<div class='mermaid'>#{escaped_text}</div>"
      end

      def modified_date(format="%B %-d, %Y")
        git_accessor = Ingest::GitAccessor.new
        date = git_accessor.author_date(current_page.source_file) || Time.new(1984,1,1)
        "Page last updated: #{date.strftime(format)}"
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

      def repo_url
        nested_dir, filename = parse_out_nested_dir_and_filename
        repo_dir = match_repo_dir(nested_dir)
        page_repo_config = config[:repo_links][repo_dir]

        if page_repo_config && page_repo_config['ref']
          at_path = at_path(page_repo_config)
          ref = Pathname(page_repo_config['ref'])
          org_repo = Pathname(page_repo_config['repo'])

          nested_dir = extract_nested_directory(nested_dir, repo_dir)
          source_file_extension = current_page.data.dita ? '.xml' : '.html.md.erb'

          "http://github.com/#{org_repo.join(Pathname('blob'), ref, Pathname(nested_dir), at_path, filename)}#{source_file_extension}"
        end
      end

      def match_repo_dir(nested_dir)
        config[:repo_links].keys
          .select{ |key| nested_dir.match(/^#{key}/) }
          .sort_by{ |key| key.length }
          .last
      end

      def parse_out_nested_dir_and_filename
        current_page.path
          .match(/\/?(.*?)\/?([^\/]*)\.html$?/)
          .captures
      end

      def extract_nested_directory(nested_dir, repo_dir)
        nested_dir = nested_dir.gsub("#{repo_dir}", '')
        nested_dir = nested_dir.sub('/', '') if nested_dir[0] == '/'

        nested_dir
      end

      def at_path(page_repo_config)
        path = page_repo_config['at_path'] || ""

        Pathname(path)
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
