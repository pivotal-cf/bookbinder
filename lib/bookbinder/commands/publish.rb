class Cli
  class Publish < BookbinderCommand
    def run(arguments)
      unless %w(local github).include?(arguments[0]) &&
          (arguments[1] == nil || arguments[1] == '--verbose')
        puts "usage: #{usage_message}"
        return 1
      end

      local_repo_dir = (arguments[0] == 'local') ? File.absolute_path('../') : nil

      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'],
                                  filename: config['pdf']['filename'],
                                  header: config['pdf']['header']}
      : nil

      publisher = Publisher.new
      success = publisher.publish repos: config['repos'],
                                  host_for_sitemap: config.fetch('cloud_foundry').fetch('public_host'),
                                  github_username: config['github']['username'],
                                  github_password: config['github']['password'],
                                  template_variables: config['template_variables'],
                                  local_repo_dir: local_repo_dir,
                                  pdf: pdf_hash,
                                  output_dir: File.absolute_path('output'),
                                  master_middleman_dir: File.absolute_path('master_middleman'),
                                  final_app_dir: File.absolute_path('final_app'),
                                  verbose: arguments[1] == '--verbose'

      success ? 0 : 1
    end

    def usage
      "<local|github> [--verbose]"
    end
  end
end