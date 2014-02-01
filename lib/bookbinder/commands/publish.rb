class Cli
  class Publish < BookbinderCommand
    def run(params)
      raise "usage: #{usage_message}" unless arguments_are_valid?(params)

      target_tag = (params[1..-1] - ['--verbose']).pop

      if target_tag
        checkout_book_at(target_tag) { generate_site_and_pdf_for(params, target_tag) }
      else
        generate_site_and_pdf_for(params)
      end
    end

    def generate_site_and_pdf_for(params, target_tag=nil)
      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'],
                                  filename: config['pdf']['filename'],
                                  header: config['pdf']['header']}
      : nil

      verbosity = params.include?('--verbose')
      location = params[0]

      success = Publisher.new.publish publication_arguments(verbosity, location, pdf_hash, target_tag)
      success ? 0 : 1
    end

    private

    def checkout_book_at(target_tag, &doc_generation)
      temp_workspace     = Dir.mktmpdir
      initial_config     = YAML.load(File.read('./config.yml'))
      book               = Book.new(full_name: initial_config.fetch('github_repo'), ref: target_tag)
      expected_book_path = File.join temp_workspace, book.directory


      FileUtils.chdir(expected_book_path) { doc_generation.call(config, target_tag) } if book.copy_from_remote(temp_workspace)
    end

    def usage
      "<local|github> [--verbose]"
    end

    def publication_arguments(verbosity, location, pdf_hash, target_tag)
      arguments = {
          repos: config.fetch('repos'),
          output_dir: File.absolute_path('output'),
          master_middleman_dir: File.absolute_path('master_middleman'),
          final_app_dir: File.absolute_path('final_app'),
          pdf: pdf_hash,
          verbose: verbosity
      }

      arguments.merge!(local_repo_dir: File.absolute_path('..')) if location == 'local'
      arguments.merge!(template_variables: config.fetch('template_variables')) if config.has_key?('template_variables')
      arguments.merge!(host_for_sitemap: config.fetch('public_host'))
      arguments.merge!(target_tag: target_tag) if target_tag
      arguments
    end

    def arguments_are_valid?(arguments)
      verbose           = arguments[1..-1].include?('--verbose')
      tag_provided      = (arguments[1..-1] - ['--verbose']).any?
      nothing_special   = arguments[1..-1].empty?

      %w(local github).include?(arguments[0]) && (tag_provided or verbose or nothing_special)
    end

    def github_credentials
      {
        github_username: config.fetch('github').fetch('username'),
        github_password: config.fetch('github').fetch('password')
      }
    end
  end
end