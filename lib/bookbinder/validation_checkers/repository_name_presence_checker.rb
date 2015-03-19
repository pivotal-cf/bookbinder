module Bookbinder
  class RepositoryNamePresenceChecker
    MissingRepositoryNameError = Class.new(RuntimeError)

    def check(config)
      all_sections = config['sections'].to_a + config['dita_sections'].to_a
      all_sections.map do |section|
        if !section['repository'] || !section['repository']['name']
          MissingRepositoryNameError.new error_message
        end
      end.last
    end

    private

    def error_message
      <<-ERROR
Cannot locate a specific section.
All sections must provide the section 'name' key under the 'repository' key:

sections:
  - repository:
      name: 'your-org/your-repo'
      ERROR
    end
  end
end