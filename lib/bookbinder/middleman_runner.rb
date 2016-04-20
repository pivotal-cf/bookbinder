require 'middleman-core'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'yaml'

module Bookbinder
  class MiddlemanRunner
    def initialize(fs, sheller)
      @fs = fs
      @sheller = sheller
    end

    def run(command,
            streams: nil,
            output_locations: nil,
            config: nil,
            local_repo_dir: nil,
            subnavs: nil,
            product_info: nil)
      streams[:out].puts "\nRunning middleman...\n\n"
      Dir.chdir(output_locations.master_dir) do
        config = {
          archive_menu: config.archive_menu,
          production_host: config.public_host,
          subnav_templates: subnavs,
          template_variables: config.template_variables,
          local_repo_dir: local_repo_dir,
          workspace: output_locations.workspace_dir,
          feedback_enabled: config.feedback_enabled,
          repo_link_enabled: config.repo_link_enabled,
          repo_links: config.repo_links,
          product_info: product_info,
          elastic_search: config.elastic_search?
        }

        fs.write(to: "bookbinder_config.yml", text: YAML.dump(config))
        sheller.run_command({'MM_ROOT' => output_locations.master_dir.to_s},
                            "middleman #{command}",
                            streams)
      end
    end

    private

    attr_reader :streams, :fs, :sheller

  end
end
