require 'anemone'
require 'pty'
require_relative 'css_link_checker'
require_relative 'sieve'
require_relative 'stabilimentum'
require_relative 'sitemap_generator'

module Bookbinder
  class Spider
    class Result
      def initialize(broken_links, sitemap, app_dir)
        @broken_links = broken_links
        @sitemap = sitemap
        @app_dir = app_dir
      end

      def has_broken_links?
        @broken_links.any?
      end

      def to_xml
        @sitemap
      end

      def to_path
        Pathname(@app_dir).join('public/sitemap.xml')
      end
    end

    def initialize(logger, app_dir: nil)
      @logger = logger
      @app_dir = app_dir || raise('Spiders must be initialized with an app directory.')
      @broken_links = []
    end

    def generate_sitemap(target_host, port)
      temp_host = "localhost:#{port}"

      sieve = Sieve.new domain: "http://#{temp_host}"
      links = crawl_from "http://#{temp_host}/index.html", sieve
      broken_links, working_links = links

      announce_broken_links broken_links

      sitemap_links = substitute_hostname(temp_host, target_host, working_links)
      Result.new(broken_links, SitemapGenerator.new.generate(sitemap_links), @app_dir)
    end

    def self.prepend_location(location, url)
      "#{URI(location).path} => #{url}"
    end

    private

    def announce_broken_links(broken_links)
      if broken_links.any?
        @logger.error "\nFound #{broken_links.count} broken links!"

        broken_links.each do |link|
          if link.include?('#')
            @logger.warn(link)
          else
            @logger.notify(link)
          end
        end

        @logger.error "\nFound #{broken_links.count} broken links!"
      else
        @logger.success "\nNo broken links!"
      end
    end

    def crawl_from(url, sieve)
      broken_links = []
      sitemap = [url]
      2.times do |i|
        is_first_pass = (i==0)

        Anemone.crawl(url) do |anemone|
          dont_visit_fragments(anemone)
          anemone.on_every_page do |page|
            if $sitemap_debug
              puts "\n\n********** Visiting page: #{page.url}\n\n#{page.body}"
            end
            broken, working = sieve.links_from Stabilimentum.new(page), is_first_pass
            broken_links.concat broken
            sitemap.concat working
          end
        end
      end

      broken_links.concat Dir.chdir(@app_dir) { CssLinkChecker.new.broken_links_in_all_stylesheets }
      [broken_links.compact.uniq, sitemap.compact.uniq]
    end

    def dont_visit_fragments(anemone)
      anemone.focus_crawl { |page| page.links.reject { |link| link.to_s.match(/%23/) } }
    end

    def substitute_hostname(temp_host, target_host, links)
      links.map { |l| l.gsub(/#{Regexp.escape(temp_host)}/, target_host) }
    end
  end
end
