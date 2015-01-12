require_relative 'section'

module Bookbinder
  class CodeExample < Section
    class InvalidSnippet < StandardError
      def initialize(repo, marker)
        super "Error with marker #{marker.cyan} #{'in'.red} #{repo.cyan}#{'.'.red}"
      end
    end

    def self.get_instance(logger,
                          section_hash: {},
                          local_repo_dir: nil,
                          destination_dir: Dir.mktmpdir,
                          target_tag: nil,
                          git_accessor: Git)
      @git_accessor = git_accessor
      store.fetch([section_hash, local_repo_dir]) { acquire(logger, section_hash, local_repo_dir, destination_dir, target_tag, git_accessor) }
    end

    def get_snippet_and_language_at(marker)
      unless @repository.copied?
        @repository.announce_skip
        return ''
      end

      prepared_snippet_at(marker)
    end

    private

    def self.acquire(logger, section_hash, local_repo_dir, destination_dir, target_tag, git_accessor)
      repository = section_hash['repository']
      raise "section repository '#{repository}' is not a hash" unless repository.is_a?(Hash)
      raise "section repository '#{repository}' missing name key" unless repository['name']
      logger.log "Gathering #{repository['name'].cyan}"

      repository = build_repository(logger, destination_dir, local_repo_dir, section_hash, target_tag, git_accessor)
      section = new(logger, repository, section_hash['subnav_template'], destination_dir)

      store[[section_hash, local_repo_dir]] = section
    end
    private_class_method :acquire

    def self.build_repository(logger, destination_dir, local_repo_dir, repo_hash, target_tag, git_accessor)
      if local_repo_dir
        GitHubRepository.build_from_local(logger, repo_hash, local_repo_dir, destination_dir)
      else
        GitHubRepository.build_from_remote(logger, repo_hash, destination_dir, target_tag, git_accessor)
      end
    end
    private_class_method :build_repository

    def prepared_snippet_at(marker)
      snippet = ''
      FileUtils.cd(@repository.copied_to) { snippet = scrape_for(marker) }

      raise InvalidSnippet.new(full_name, marker) if snippet.empty?
      lines = snippet.split("\n")
      language_match = lines[0].match(/code_snippet #{Regexp.escape(marker)} start (\w+)/)
      language = language_match[1] if language_match
      [lines[1..-2].join("\n"), language]
    end

    def scrape_for(marker)
      locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
      result = `#{locale} find . -exec sed -ne '/code_snippet #{marker} start/,/code_snippet #{marker} end/ p' {} \\; 2> /dev/null`
      result = "" unless result.lines.last && result.lines.last.match(/code_snippet #{marker} end/)
      result
    end
  end
end

