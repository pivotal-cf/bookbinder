class Middleman::Cli::BuildAction
  def handle_error(file_name, response, e=Thor::Error.new(response))
    our_errors = [GitClient::TokenException,
                  Bookbinder::CodeExample::InvalidSnippet,
                  QuicklinksRenderer::BadHeadingLevelError]
    raise e if our_errors.include?(e.class)

    original_handle_error(e, file_name, response)
  end

  private

  def original_handle_error(e, file_name, response)
    base.had_errors = true

    base.say_status :error, file_name, :red
    if base.debugging
      raise e
      exit(1)
    elsif base.options["verbose"]
      base.shell.say response, :red
    end
  end
end

module Bookbinder
  class MiddlemanRunner
    def initialize(logger)
      @logger = logger
    end

    def run(middleman_dir, template_variables, local_repo_dir, file_modification_cache, verbose = false, sections = [], production_host=nil, git_accessor=Git)
      @logger.log "\nRunning middleman...\n\n"

      within(middleman_dir) do
        invoke_against_current_dir(file_modification_cache, local_repo_dir, production_host, sections, template_variables, verbose, git_accessor)
      end
    end

    private

    def within(temp_root, &block)
      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      original_mm_root  = ENV['MM_ROOT']
      ENV['MM_ROOT']    = temp_root

      Dir.chdir(temp_root) { block.call }

      ENV['MM_ROOT']    = original_mm_root
    end

    def invoke_against_current_dir(file_modification_cache, local_repo_dir, production_host, sections, template_variables, verbose, git_accessor)
      builder = Middleman::Cli::Build.shared_instance(verbose)

      config = {
          template_variables: template_variables,
          relative_links: false,
          subnav_templates: subnavs_by_dir_name(sections),
          local_repo_dir: local_repo_dir,
          production_host: production_host,
          filecache: file_modification_cache,
          git_accessor: git_accessor,
      }

      config.each { |k, v| builder.config[k] = v }
      Middleman::Cli::Build.new([], {quiet: !verbose}, {}).invoke :build, [], {verbose: verbose}
    end

    def subnavs_by_dir_name(sections)
      sections.reduce({}) do |final_map, section|
        namespace = section.directory.gsub('/', '_')
        template = section.subnav_template || 'default'

        final_map.merge(namespace => template)
      end
    end
  end
end