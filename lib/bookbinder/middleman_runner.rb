require 'git/lib'
require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require_relative 'code_example_reader'

class Middleman::Cli::BuildAction
  def handle_error(file_name, response, e=Thor::Error.new(response))
    our_errors = [Bookbinder::CodeExampleReader::InvalidSnippet,
                  QuicklinksRenderer::BadHeadingLevelError,
                  Git::GitExecuteError]
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
    def initialize(logger, git_accessor)
      @logger = logger
      @git_accessor = git_accessor
    end

    def run(output_locations,
            config,
            cloner,
            verbose = false,
            subnav_templates_by_directory = {})
      @logger.log "\nRunning middleman...\n\n"

      within(output_locations.master_dir) do
        invoke_against_current_dir(output_locations.workspace_dir,
                                   config.public_host,
                                   subnav_templates_by_directory,
                                   config.template_variables,
                                   config.archive_menu,
                                   verbose,
                                   cloner)
      end
    end

    private

    attr_reader :git_accessor

    def within(temp_root, &block)
      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      original_mm_root  = ENV['MM_ROOT']
      ENV['MM_ROOT']    = temp_root.to_s

      Dir.chdir(temp_root) { block.call }

      ENV['MM_ROOT']    = original_mm_root
    end

    def invoke_against_current_dir(workspace_dir,
                                   production_host,
                                   subnav_templates,
                                   template_variables,
                                   archive_menu,
                                   verbose,
                                   cloner)
      builder = Middleman::Cli::Build.shared_instance(verbose)

      config = {
        archive_menu: archive_menu,
        cloner: cloner,
        production_host: production_host,
        relative_links: false,
        subnav_templates: subnav_templates,
        template_variables: template_variables,
        workspace: workspace_dir,
      }

      config.each { |k, v| builder.config[k] = v }
      Middleman::Cli::Build.new([], {quiet: !verbose}, {}).invoke :build, [], {verbose: verbose}
    end
  end
end
