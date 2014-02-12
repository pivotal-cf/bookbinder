class Spider

  include ShellOut
  include BookbinderLogger

  def initialize(final_app_dir=nil)
    @app_dir = final_app_dir
  end

  def generate_sitemap(host)
    @broken_links, working_links = find_all_links
    announce_broken_links @broken_links

    sitemap_file = File.join(@app_dir, 'public', 'sitemap.txt')
    File.open(sitemap_file, 'w') do |file|
      file.write substitute_hostname(host, working_links.join("\n"))
    end
  end

  def has_broken_links?
    @broken_links.any? if @broken_links
  end

  def port
    4534
  end

  private

  def announce_broken_links(links)
    if links.any?
      log "\nFound #{links.count} broken links!".red
      links.each { |line| log line }
    else
      log "\nNo broken links!".green
    end
  end

  def find_all_links
    links = []
    Dir.chdir(@app_dir) { links = capture_links }
    links
  end

  def capture_links
    open_results  = Open3.popen3("ruby app.rb #{port}")
    stderr        = open_results[2]
    wait_thread   = open_results[3]

    once_sinatra_has_started(stderr) do
      consume_stream_in_separate_thread(stderr)
      crawl_from "http://localhost:#{port}/index.html"
    end
  ensure
    Process.kill 'KILL', wait_thread[:pid]
  end

  def crawl_from(url)
    broken_links = []
    sitemap = [url]

    Anemone.crawl(url) do |anemone|
      anemone.on_every_page do |page|
        if page.not_found?
          broken_links << page.url.to_s
        else
          sitemap.concat page.links.map(&:to_s)
        end
      end
    end

    [broken_links.uniq, sitemap.uniq]
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
