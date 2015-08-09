require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'yaml'
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
    def initialize(streams, fs)
      @out = streams[:out]
      @fs = fs
    end

    def run(output_locations,
            config,
            local_repo_dir,
            verbose,
            subnav_templates_by_directory)
      out.puts "\nRunning middleman...\n\n"

      within(output_locations.master_dir) do
        config = {
          archive_menu: config.archive_menu,
          production_host: config.public_host,
          subnav_templates: subnav_templates_by_directory,
          template_variables: config.template_variables,
          local_repo_dir: local_repo_dir,
          workspace: output_locations.workspace_dir,
        }

        fs.write(to: "bookbinder_config.yml", text: YAML.dump(config))

        Middleman::Cli::Build.new([], {quiet: !verbose}, {}).invoke :build, [], {verbose: verbose}
      end
    end

    private

    attr_reader :out, :fs

    def within(temp_root, &block)
      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      original_mm_root  = ENV['MM_ROOT']
      ENV['MM_ROOT']    = temp_root.to_s

      Dir.chdir(temp_root) { block.call }

      ENV['MM_ROOT']    = original_mm_root
    end
  end
end
