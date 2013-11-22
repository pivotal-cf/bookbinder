class MiddlemanRunner

  include BookbinderLogger
  include ShellOut

  def run(middleman_dir)
    log 'Running middleman...'

    # awful hacks to eliminate the impact of global state in middleman. when will it end?
    Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
    ENV['MM_ROOT'] = middleman_dir

    Dir.chdir(middleman_dir) do
      build_command = Middleman::Cli::Build.new [], {:quiet => true}, {}
      build_command.invoke :build, [], {:instrument => false}
    end
  end
end