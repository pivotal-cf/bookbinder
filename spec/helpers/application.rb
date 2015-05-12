require_relative '../helpers/redirection'
require_relative '../../lib/bookbinder/cli'
require_relative '../helpers/use_fixture_repo'
require_relative '../helpers/git_fake'
require 'pathname'
require 'tmpdir'

module Bookbinder
  class Application
    include Redirection

    def initialize(git_client = GitFake.new)
      @git_client = git_client
      @cli_client = Cli.new(git_client)
    end

    def bind_book_from_remote(book, silent: true, &expectation)
      command = Proc.new { cli_client.run(%w(bind remote --verbose)) }
      execute_in_book(book, command, silent, expectation)
    end

    def bind_book_from_local(book, silent: true, &expectation)
      command = Proc.new { cli_client.run(%w(bind local --verbose)) }
      execute_in_book(book, command, silent, expectation)
    end

    def bind_book_with_dita_options(book, silent: true, dita_options: '', &expectation)
      command = Proc.new { cli_client.run(%W(bind local --verbose --dita-flags=#{dita_options})) }
      execute_in_book(book, command, silent, expectation)
    end

    private

    attr_reader :cli_client, :git_client

    def execute_in_book(book, command, silent, block)
      repo_name = book.name
      temp_library = tmp_subdir 'repositories'
      FileUtils.cp_r File.join(Bookbinder::RepoFixture.repos_dir, '.'), temp_library
      FileUtils.cd(File.join(temp_library, repo_name)) do
        silent ? swallow_stdout { command.call } : command.call
        block.call
      end
    end

    def tmp_subdir(name)
      tmpdir.join(name).tap do |dir|
        FileUtils.mkdir_p dir
      end
    end

    def tmpdir
      @tmpdir ||= Pathname(Dir.mktmpdir)
    end
  end

end
