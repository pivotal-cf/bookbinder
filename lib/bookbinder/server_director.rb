class ServerDirector
  include BookbinderLogger

  def initialize(directory: nil, port: 41722)
    @directory = directory
    @port = port
  end

  def use_server
    Dir.chdir(@directory) do
      POpen4::popen4("puma -p #{@port}") do |stdout, _, _, pid|
        begin
          wait_for_server(stdout)
          yield @port
        ensure
          stop_server(pid)
        end
      end
    end
  end

  private

  def wait_for_server(io)
    begin
      line = io.gets
      raise 'Puma could not start' if line.nil?

      log "Vienna says, #{line}"
    end until line.include?('Listening on')

    log 'Vienna is lovely this time of year.'
  end

  def stop_server(pid)
    Process.kill 'KILL', pid
  end
end