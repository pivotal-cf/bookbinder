require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require_relative 'code_example'

class Middleman::Cli::BuildAction
  def handle_error(file_name, response, e=Thor::Error.new(response))
    our_errors = [Bookbinder::GitClient::TokenException,
                  Bookbinder::CodeExample::InvalidSnippet,
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
    def initialize(logger)
      @logger = logger
    end

    def run(middleman_dir, template_variables, local_repo_dir, verbose = false, book = nil, sections = [], production_host=nil, archive_menu=nil, git_accessor=Git)
      @logger.log "\nRunning middleman...\n\n"

      within(middleman_dir) do
        invoke_against_current_dir(local_repo_dir, production_host, book, sections, template_variables, archive_menu, verbose, git_accessor)
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

    def invoke_against_current_dir(local_repo_dir, production_host, book, sections, template_variables, archive_menu, verbose, git_accessor)
      builder = Middleman::Cli::Build.shared_instance(verbose)

      config = {
          local_repo_dir: local_repo_dir,
          production_host: production_host,
          git_accessor: git_accessor,
          sections: sections,
          book: book,
          template_variables: template_variables,
          relative_links: false,
          subnav_templates: subnavs_by_dir_name(sections),
          archive_menu: archive_menu
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
