class Spider

  include ShellOut
  include BookbinderLogger

  def initialize(output_dir, final_app_dir)
    @output_dir = output_dir
    @app_dir = final_app_dir
  end

  def parse_log(contents)
    return [] if contents.include? 'Found no broken links.'
    matchLines = contents.match('Found [0-9]+ broken[^~]+FINISHED').to_s.lines
    matchLines.map { |url| url[/^http:\/\/localhost[^\/]*(.*)/, 1] }.compact
  end

  def spider_page(url, log_file)
    shell_out "wget --spider --output-file=#{log_file} --execute robots=off --wait 0 --recursive --level=10 --no-directories --page-requisites #{url}", true
  end

  def find_broken_links(log_file)
    Dir.chdir(@app_dir) do
      begin
        open_results = Open3.popen3('ruby app.rb 4534')
        stderr = open_results[2]
        wait_thread = open_results[3]

        begin
          stderr_line = stderr.gets
          log "Sinatra says: #{stderr_line.chomp}"
        end until stderr_line.include?('has taken the stage')

        log 'Sinatra appears to have taken the stage!'
        consume_stream_in_separate_thread stderr
        spider_page('http://localhost:4534/index.html', log_file)

      ensure
        Process.kill 'KILL', wait_thread[:pid]
      end
    end

    parse_log File.read(log_file)
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