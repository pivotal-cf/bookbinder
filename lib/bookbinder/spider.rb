class Spider

  include ShellOut
  include BookbinderLogger

  def initialize(final_app_dir=nil, log_file=nil)
    @app_dir = final_app_dir
    @log_file = log_file || File.join(Dir.mktmpdir, 'wget.log')
  end

  def generate_sitemap(host, final_public_dir)
    sitemap_file = File.join(final_public_dir, 'sitemap.txt')
    File.open(sitemap_file, 'w') do |file|
      file.write(shell_out "grep \\\\.html #{@log_file} | grep \"\\-\\-\" | sed s/^.*localhost:4534/http:\\\\/\\\\/#{host}/ | uniq")
    end
  end

  def has_broken_links?
    links = find_broken_links
    announce_broken_links(links)
    links.any?
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

  def find_broken_links
    Dir.chdir(@app_dir) { log_broken_links }
    parse_log
  end

  def log_broken_links
    open_results  = Open3.popen3('ruby app.rb 4534')
    stderr        = open_results[2]
    wait_thread   = open_results[3]

    once_sinatra_has_started(stderr) do
      consume_stream_in_separate_thread(stderr)
      crawl_from 'http://localhost:4534/index.html'
    end

  ensure
    Process.kill 'KILL', wait_thread[:pid]
  end

  def crawl_from(url)
    shell_out "wget --spider --output-file=#{@log_file} --execute robots=off --wait 0 --recursive --level=10 --no-directories --page-requisites #{url}", true
  end

  def parse_log
    contents = File.read(@log_file)
    return [] if contents.include? 'Found no broken links.'
    matchLines = contents.match('Found [0-9]+ broken[^~]+FINISHED').to_s.lines
    matchLines.map { |url| url[/^http:\/\/localhost[^\/]*(.*)/, 1] }.compact
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
end
