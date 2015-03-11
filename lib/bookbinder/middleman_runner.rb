require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require_relative 'values/code_example'
require_relative 'code_example_reader'

class Middleman::Cli::BuildAction
  def handle_error(file_name, response, e=Thor::Error.new(response))
    our_errors = [Bookbinder::GitClient::TokenException,
                  Bookbinder::CodeExampleReader::InvalidSnippet,
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

    def run(middleman_dir,
            workspace_dir,
            template_variables,
            local_repo_dir,
            verbose = false,
            subnav_templates_by_directory = {},
            production_host=nil,
            archive_menu=nil)
      @logger.log "\nRunning middleman...\n\n"

      within(middleman_dir) do
        invoke_against_current_dir(local_repo_dir,
                                   workspace_dir,
                                   production_host,
                                   subnav_templates_by_directory,
                                   template_variables,
                                   archive_menu,
                                   verbose)
      end
    end

    private

    attr_reader :git_accessor

    def within(temp_root, &block)
      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      original_mm_root  = ENV['MM_ROOT']
      ENV['MM_ROOT']    = temp_root

      Dir.chdir(temp_root) { block.call }

      ENV['MM_ROOT']    = original_mm_root
    end

    def invoke_against_current_dir(local_repo_dir,
                                   workspace_dir,
                                   production_host,
                                   subnav_templates,
                                   template_variables,
                                   archive_menu,
                                   verbose)
      builder = Middleman::Cli::Build.shared_instance(verbose)

      config = {
          local_repo_dir: local_repo_dir,
          workspace: workspace_dir,
          production_host: production_host,
          git_accessor: git_accessor,
          template_variables: template_variables,
          relative_links: false,
          subnav_templates: subnav_templates,
          archive_menu: archive_menu
      }

      config.each { |k, v| builder.config[k] = v }
      Middleman::Cli::Build.new([], {quiet: !verbose}, {}).invoke :build, [], {verbose: verbose}
    end
  end
end
