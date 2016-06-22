require 'nokogiri'
require_relative '../css_link_checker'
require_relative 'redirection'

module Bookbinder
  module Postprocessing
    class LinkChecker
      def initialize(fs, root_path, output_streams)
        @fs = fs
        @root_path = root_path
        @output_streams = output_streams
        @broken_link_count = 0

        @convert_to_relative = %r{\A.*#{root_path.to_s}/public}
        @default_link_exclusions = %r{\A(?:https?://|javascript:|mailto:)}
        @excluded_pages = %r{\A/(?:404\.html|subnavs|javascripts|stylesheets|style_guide)}
      end

      def check!(link_exclusions = /(?!.*)/)
        @output_streams[:out].puts "\nChecking for broken links..."
        @redirects = Redirection.new(@fs, File.join(@root_path, 'redirects.rb'))
        load_page_links

        report_broken_links!(link_exclusions)
        report_orphaned_pages!

        if has_errors?
          err "\nFound #{@broken_link_count} broken links!"
        else
          out "\nNo broken links!"
        end
      end

      def has_errors?
        @broken_link_count > 0
      end

      private

      def report_broken_links!(link_exclusions)
        @page_links.each do |page, links|
          links.each do |link|
            next if skip?(link, link_exclusions)

            absolute_link, fragment = normalize_link(link, page)

            if !page_exists?(absolute_link) && !file_exists?(absolute_link)
              @broken_link_count += 1
              err "#{page} => #{absolute_link}#{fragment ? "##{fragment}" : ''}"
            end
          end
        end

        broken_css_links = Dir.chdir(@root_path) { CssLinkChecker.new.broken_links_in_all_stylesheets }
        broken_css_links.reject! { |link| link_exclusions.match(link) }

        @broken_link_count += broken_css_links.size
        broken_css_links.each do |link|
          err link
        end
      end

      def report_orphaned_pages!
        linked_pages = @page_links.map do |page, links|
          links.map do |link|
            normalize_link(link, page)[0]
          end
        end.flatten.uniq

        orphaned_pages = @page_links.keys.reject { |page| page == '/index.html' || linked_pages.include?(page) }
        if orphaned_pages.size > 0
          err "\nOrphaned pages"
          orphaned_pages.each do |page|
            err "No links to => #{page}"
          end
        end
      end

      def skip?(link_path, link_exclusions)
        @default_link_exclusions.match(link_path) || link_path.match(link_exclusions)
      end

      def page_exists?(link)
        @page_links.has_key?(link) || @redirects.redirected?(link)
      end

      def normalize_link(link, page)
        return [page, link.sub(/\A#/, '')] if link[0] == '#'

        absolute_link = link[0] == '/' ? link : File.expand_path(link, File.dirname(page))
        absolute_link.split('#')
      end

      def file_exists?(link)
        full_path = File.join(@root_path, 'public', link)
        @fs.is_file?(full_path) || (@fs.is_dir?(full_path) && @fs.is_file?(File.join(full_path, 'index.html')))
      end

      def load_page_links
        files = @fs.find_files_with_ext('html', File.join(@root_path, 'public'))

        @page_links = files.each.with_object({}) do |file_path, links|
          public_path = file_path.sub(@convert_to_relative, '')

          if !@excluded_pages.match(public_path)
            html = Nokogiri::HTML(@fs.read(file_path))

            links[public_path] = [
              html.css('a[href]').map { |link| link['href'] },
              html.css('img').map { |image| image['src'] }
            ].flatten
          end
        end
      end

      def out(str)
        @output_streams[:out].puts(str)
      end

      def err(str)
        @output_streams[:err].puts(str)
      end
    end
  end
end
