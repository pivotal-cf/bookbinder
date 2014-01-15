class Cli
  class Publish < BookbinderCommand
    def run(params)
      raise "usage: #{usage_message}" unless arguments_are_valid?(params)


      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'],
                                  filename: config['pdf']['filename'],
                                  header: config['pdf']['header']}
      : nil

      verbosity = params[1] == '--verbose'
      location = params[0]
      success = Publisher.new.publish publication_arguments(verbosity, location, pdf_hash)

      success ? 0 : 1
    end

    private

    def usage
      "<local|github> [--verbose]"
    end

    def publication_arguments(verbosity, location, pdf_hash)
      arguments = {
          repos: config.fetch('repos'),
          output_dir: File.absolute_path('output'),
          master_middleman_dir: File.absolute_path('master_middleman'),
          local_repo_dir: (location == 'local') ? File.absolute_path('../') : nil,
          final_app_dir: File.absolute_path('final_app'),
          pdf: pdf_hash,
          verbose: verbosity
      }

      arguments.merge!({template_variables: config.fetch('template_variables')}) if config.has_key?('template_variables')
      arguments.merge!(host_for_sitemap: config['cloud_foundry'].fetch('public_host')) if config.has_key?('cloud_foundry') and config['cloud_foundry']
      arguments.merge!({github_username: config['github']['username'],
                        github_password: config['github']['password']}) if config.has_key?('github')

      arguments
    end

    def arguments_are_valid?(arguments)
      %w(local github).include?(arguments[0]) && (arguments[1] == nil || arguments[1] == '--verbose')
    end
  end
end