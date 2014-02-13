class Spider
  attr_reader :port

  include ShellOut
  include BookbinderLogger

  def initialize(final_app_dir=nil, root_page=nil, port=4534)
    @app_dir = final_app_dir
    domain = "http://localhost:#{port}"
    @root_page = root_page || "#{domain}/index.html"
    @sieve = Sieve.new domain: domain
    @port = port
  end

  def generate_sitemap(host)
    links = []
    Dir.chdir(@app_dir) { links = capture_links @root_page }
    @broken_links, working_links = links

    announce_broken_links @broken_links

    write_sitemap_txt(host, working_links)
  end

  def has_broken_links?
    @broken_links.any? if @broken_links
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
      broken_links.each { |line| log line }
    else
      log "\nNo broken links!".green
    end
  end

  def capture_links(page)
    open_results  = Open3.popen3("ruby app.rb #{port}")
    stderr        = open_results[2]
    wait_thread   = open_results[3]

    once_sinatra_has_started(stderr) do
      consume_stream_in_separate_thread(stderr)
      crawl_from page
    end
  ensure
    Process.kill 'KILL', wait_thread[:pid]
  end

  def crawl_from(url)
    broken_links = []
    sitemap = [url]

    2.times do |i|
      Anemone.crawl(url) do |anemone|
        anemone.focus_crawl { |page| page.links.reject {|link| link.to_s.match(/%23/)} }
        anemone.on_every_page { |page| @sieve.links_into Stabilimentum.new(page), broken_links, sitemap, i == 0 }
      end
    end

    [broken_links.compact, sitemap.compact.uniq]
  end

  def once_sinatra_has_started(stderr)
    begin
      stderr_line = stderr.gets
      log "Sinatra says: #{stderr_line.chomp}"
    end until stderr_line.include?('has taken the stage')

    log 'Sinatra appears to have taken the stage!'
    yield
  end

  # avoids deadlocks by ensuring sinatra doesn't hang waiting to write to stderr
  def consume_stream_in_separate_thread(io_stream)
    Thread.new do
      s = nil
      while io_stream.read(1024, s)
      end
    end
  end

  def substitute_hostname(host, links_string)
    links_string.gsub(/localhost:#{port}/, host)
  end
end
