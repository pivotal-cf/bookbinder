require 'octokit'

module Bookbinder
  class GitClient < Octokit::Client
    class GitClient::TokenException < StandardError;
    end

    def initialize(logger, *args)
      @logger = logger
      super(*args)
    end

    def head_sha(full_name)
      commits(full_name).first.sha
    end

    def create_tag!(full_name, tagname, ref)
      @logger.log 'Tagging ' + full_name.cyan
      tag_result = create_tag(full_name, "tags/#{tagname}", 'Tagged by Bookbinder', ref, 'commit', 'Bookbinder', 'bookbinder@cloudfoundry.org', Time.now.iso8601)
      create_ref(full_name, "tags/#{tagname}", tag_result.sha)
    rescue Octokit::Unauthorized, Octokit::NotFound
      raise_error_with_context
    end

    def archive_link(*args)
      super
    rescue Octokit::Unauthorized, Octokit::NotFound
      raise_error_with_context
    end

    def tags(*args)
      super
    rescue Octokit::Unauthorized, Octokit::NotFound
      raise_error_with_context
    end

    def refs(*args)
      super
    rescue Octokit::Unauthorized, Octokit::NotFound
      raise_error_with_context
    end

    def last_modified_date_of(full_name, target_ref, file)
      commits = commits(full_name, target_ref, path: file)
      commits.first[:commit][:author][:date]
    end

    private

    def commits(*args)
      super
    rescue Octokit::Unauthorized, Octokit::NotFound
      raise_error_with_context
    end

    def raise_error_with_context
      absent_token_message = '  Cannot access repository! You must set $GITHUB_API_TOKEN.'
      invalid_token_message = '  Cannot access repository! Does your $GITHUB_API_TOKEN have access to this repository? Does it exist?'

      ENV['GITHUB_API_TOKEN'] ? raise(TokenException.new(invalid_token_message)) : raise(TokenException.new(absent_token_message))
    end
  end
end
