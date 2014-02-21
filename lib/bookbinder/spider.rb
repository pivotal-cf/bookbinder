require 'pty'

class Spider
  include ShellOut
  include BookbinderLogger

  def initialize(final_app_dir=nil, root_page=nil, port=1024+rand(65535-1024))
    @app_dir = final_app_dir
    domain = "http://localhost:#{port}"
    @root_page = root_page || "#{domain}/index.html"
    @sieve = Sieve.new domain: domain
    @port = port
    @broken_links = []
  end

  def generate_sitemap(host)
    links = []
    Dir.chdir(@app_dir) { links = capture_links @root_page }
    @broken_links, working_links = links

    announce_broken_links @broken_links

    write_sitemap_txt(host, working_links)
  end

  def has_broken_links?
    @broken_links.any? {|link| !link.include?('#') } if @broken_links
  end

  def self.prepend_location(location, url)
    "#{URI(location).path} => #{url}"
  end

  private

  def write_sitemap_txt(host, working_links)
    sitemap_file = File.join(@app_dir, 'public', 'sitemap.txt')
    File.open(sitemap_file, 'w') do |file|
      file.write substitute_hostname(host, working_links.join("\n"))
    end
  end

  def announce_broken_links(broken_links)
    if broken_links.any?
      log "\nFound #{broken_links.count} broken links!".red
      broken_links.each do |link|
        color = link.include?('#') ? :yellow : :blue
        log link.send(color)
      end
    else
      log "\nNo broken links!".green
    end
  end

  def capture_links(page)
    io, wait_thread_pid = start_web_server

    once_server_has_started(io) do
      consume_stream_in_separate_thread(io)
      crawl_from page
    end
  ensure
    Process.kill 'KILL', wait_thread_pid
  end

  def start_web_server
    open_results  = PTY.spawn("rackup -p #{@port}")
    stdouts       = open_results[0]
    pid           = open_results[2]

    return stdouts, pid
  end

  def crawl_from(url)
    broken_links = []
    sitemap = [url]

    2.times do |i|
      Anemone.crawl(url) do |anemone|
        anemone.focus_crawl { |page| page.links.reject {|link| link.to_s.match(/%23/)} }
        anemone.on_every_page do |page|
          broken, working = @sieve.links_from Stabilimentum.new(page), i == 0
          broken_links.concat broken
          sitemap.concat working
        end
      end
    end

    broken_links.concat @sieve.broken_links_in_all_stylesheets
    [broken_links.compact.uniq, sitemap.compact.uniq]
  end

  def once_server_has_started(io)
    begin
      line = io.gets
      log "Vienna says, #{line}"
    end until line && line.include?('Listening on')

    log 'Vienna is lovely, this time of year.'
    yield
  end

  # avoids deadlocks by ensuring rack doesn't hang waiting to write to stderr
  def consume_stream_in_separate_thread(io_stream)
    Thread.new do
      s = nil
      while io_stream.read(1024, s)
      end
    end
  end

  def substitute_hostname(host, links_string)
    links_string.gsub(/localhost:#{@port}/, host)
  end
end
