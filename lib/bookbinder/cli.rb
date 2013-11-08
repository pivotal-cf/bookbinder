class Cli

  include BookbinderLogger

  def run(args)
    log 'No command supplied' and return if args.empty?
    command = args[0]
    case command
      when 'publish'
        Publish.new.run args[1..-1]
      else
        log "Unrecognized command '#{command}'"
    end
  end


  class Publish
    def run(args_array)

      usage_message = 'usage: publish <local|github>'

      unless args_array.size == 1
        puts usage_message
        return 1
      end

      unless %w(local github).include?(args_array[0])
        puts usage_message
        return 1
      end

      local_repo_dir = (args_array[0] == 'local') ? File.absolute_path('../') : nil

      config = YAML.load File.read('./config.yml')
      repos = config['repos']

      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'], filename: config['pdf']['filename']} : nil

      publisher = Publisher.new
      success = publisher.publish repos: repos,
                                  output_dir: File.absolute_path('output'),
                                  master_middleman_dir: File.absolute_path('master_middleman'),
                                  local_repo_dir: local_repo_dir,
                                  final_app_dir: File.absolute_path('final_app'),
                                  github_username: config['github_username'],
                                  github_password: config['github_password'],
                                  pdf: pdf_hash

      success ? 0 : 1
    end
  end

end

