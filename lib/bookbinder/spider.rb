class Spider
  attr_reader :port

  include ShellOut
  include BookbinderLogger

  def initialize(final_app_dir=nil, root_page=nil, port=4534)
    @app_dir = final_app_dir
    @root_page = root_page || "http://localhost:#{port}/index.html"
    @port = port
  end

  def generate_sitemap(host)
    @broken_links, working_links = find_all_links_through root_page
    announce_broken_links @broken_links

    sitemap_file = File.join(@app_dir, 'public', 'sitemap.txt')
    File.open(sitemap_file, 'w') do |file|
      file.write substitute_hostname(host, working_links.join("\n"))
    end
  end

  def has_broken_links?
    @broken_links.any? if @broken_links
  end

  private
  attr_reader :root_page

  def announce_broken_links(broken_links)
    if broken_links.any?
      log "\nFound #{broken_links.count} broken links!".red
      broken_links.each { |line| log line }
    else
      log "\nNo broken links!".green
    end
  end

  def find_all_links_through(page)
    links = []
    Dir.chdir(@app_dir) { links = capture_links page }
    links
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

    Anemone.crawl(url) do |anemone|
      anemone.focus_crawl { |page| page.links.reject {|link| link.to_s.match(/%23/)} }
      anemone.on_every_page { |page| sieve_links_into page, broken_links, sitemap }
    end

    [broken_links.compact, sitemap.compact.uniq]
  end

  def sieve_links_into(page, broken_links, sitemap)
    if page.not_found?
      broken_links << page.url.to_s
    else
      broken_links.concat broken_anchors(page) if page.doc
      sitemap << page.url.to_s
    end
  end

  def broken_anchors(page)
    fragment_identifiers(page).select { |identifier| no_target_for identifier, on: page }
  end

  def fragment_identifiers(page)
    anchor_tags = page.doc.css('a')
    anchor_tags.reduce([]) do |identifiers, anchor|
      id = fragment_id(anchor)
      identifiers << id if id
      identifiers
    end
  end

  def fragment_id(anchor)
    if anchor['href']
      possible_tag = anchor['href'].match(/^#.*/).to_s
      possible_tag unless possible_tag.empty?
    end
  end

  def no_target_for(anchor, on: nil)
    id_selector = anchor
    name_selector = "[name=#{anchor.to_s.gsub('#', '')}]"
    on.doc.css(id_selector).none? && on.doc.css(name_selector).none?
  rescue Nokogiri::CSS::SyntaxError
    true
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
