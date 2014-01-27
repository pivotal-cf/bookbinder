class MiddlemanRunner

  include BookbinderLogger
  include ShellOut

  def run(middleman_dir, template_variables, verbose = false, repos = [])
    log 'Running middleman...'

    # awful hacks to eliminate the impact of global state in middleman. when will it end?
    Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
    ENV['MM_ROOT'] = middleman_dir

    Dir.chdir(middleman_dir) do
      build_command = Middleman::Cli::Build.new [], {:quiet => !verbose}, {}
      Middleman::Cli::Build.shared_instance(verbose).config[:template_variables] = template_variables
      Middleman::Cli::Build.shared_instance(verbose).config[:relative_links] = false
      Middleman::Cli::Build.shared_instance(verbose).config[:topics] = map_dir_to_subnav(repos)
      build_command.invoke :build, [], {:verbose => verbose}
    end
  end

  private

  def map_dir_to_subnav(repos)
    repos.reduce({}) do |final_map, repository|
      dir_namespace = repository.directory.gsub('/', '_')
      subnav_template_ref = repository.subnav_template

      final_map.merge(dir_namespace => subnav_template_ref)
    end
  end
end