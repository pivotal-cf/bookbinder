require 'anemone'
require 'pty'
require_relative 'css_link_checker'
require_relative 'sieve'
require_relative 'stabilimentum'

module Bookbinder
  class Spider
    class Result
      def initialize(broken_links)
        @broken_links = broken_links
      end

      def has_broken_links?
        @broken_links.any?
      end

      def announce_broken_links(streams)
        if @broken_links.none?
          streams[:out].puts "\nNo broken links!"
        else
          streams[:err].puts(<<-MESSAGE)

Found #{@broken_links.count} broken links!

#{@broken_links.sort.join("\n")}

Found #{@broken_links.count} broken links!
          MESSAGE
        end
      end
    end

    def self.prepend_location(location, url)
      "#{URI(location).path} => #{url}"
    end

    def initialize(app_dir: nil)
      @app_dir = app_dir || raise('Spiders must be initialized with an app directory.')
    end

    def find_broken_links(port, broken_link_exclusions: /(?!.*)/)
      temp_host = "localhost:#{port}"
      sieve = Sieve.new domain: "http://#{temp_host}"
      links = crawl_from "http://#{temp_host}/index.html", sieve
      broken_links = links.first
      public_broken_links = broken_links.reject {|l| l.match(broken_link_exclusions)}

      Result.new(public_broken_links)
    end

    private

    attr_reader :app_dir

    def crawl_from(url, sieve)
      broken_links = []
      sitemap = [url]
      2.times do |i|
        is_first_pass = (i==0)

        Anemone.crawl(url) do |anemone|
          dont_visit_fragments(anemone)
          anemone.on_every_page do |page|
            broken, working = sieve.links_from(Stabilimentum.new(page), is_first_pass)
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
  end
end
