class Cli
  class PushLocalToStaging < BookbinderCommand
    def run(_)
      cf_command_runner = CfCommandRunner.new config.cf_staging_credentials, tracefile
      Pusher.new(cf_command_runner).push('./final_app')
      0
    end

    def self.usage
      ''
    end

    private

    def tracefile
      namespace = Book.new(full_name: config.book_repo).short_name
      File.join '/tmp', Archive.filename_scheme(namespace, ENV['BUILD_NUMBER'], 'log')
    end
  end
end
