require 'thor'

require_relative 'ingest/git_accessor'
require_relative 'streams/colorized_stream'
require_relative 'colorizer'
require_relative 'commands/collection'

module Bookbinder
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    map '--version' => :version
    map '--help' => :help

    desc '--version', 'Print the version of bookbinder'
    def version
      gemspec = File.expand_path('../../../bookbinder.gemspec', __FILE__)
      say "bookbinder #{Gem::Specification::load(gemspec).version}"
    end

    desc '--help', 'Print this message'
    def help(command=nil)
      super
    end

    desc 'generate <book_name>', 'Generate a skeleton book that can be bound with "bookbinder bind"'
    def generate(book_name)
      code = legacy_commands.generate(book_name)
      raise Thor::Error, '' if code != 0
    end

    desc 'bind <local|remote> [options]', 'Bind the sections specified in config.yml from <local> or <remote> into the final_app directory'
    option :verbose, type: :boolean
    option 'dita-flags', desc: '--dita-flags=\"<dita-option>=<value>\"'
    option :require_valid_subnav_links, type: :boolean, desc: 'Check that subnav link targets exist, always true for remote'
    def bind(source)
      code = legacy_commands.bind(source, options[:verbose], options['dita-flags'], options[:require_valid_subnav_links])
      raise Thor::Error, '' if code != 0
    end

    desc 'punch <git tag>', 'Apply the specified <git tag> to your book, sections, and layout repo'
    def punch(git_tag)
      code = legacy_commands.punch(git_tag)
      raise Thor::Error, '' if code != 0
    end

    desc 'update_local_doc_repos', 'Run `git pull` on all sections that exist at the same directory level as your book directory'
    def update_local_doc_repos
      code = legacy_commands.update_local_doc_repos
      raise Thor::Error, '' if code != 0
    end

    desc 'watch [repo1 [repo2]]', 'Bind and serve a local book, watching for changes'
    long_desc <<-LONG_DESC
Bind and serve a local book, watching for changes

Optionally, you can provide a subset of the repositories in the book to be watched.
This will exclude any repositories not specified from being available in the bound book, even if they exist on your file system.
    LONG_DESC
    def watch(*repos)
      code = legacy_commands.watch(repos)
      raise Thor::Error, '' if code != 0
    end

    desc 'imprint <local|remote> [options]', 'Generate a PDF for a given book'
    option :verbose, type: :boolean
    option 'dita-flags', desc: '--dita-flags=\"<dita-option>=<value>\"'
    def imprint(source)
      code = legacy_commands.imprint(source, options[:verbose], options['dita-flags'])
      raise Thor::Error, '' if code != 0
    end

    def method_missing(command, *args)
      puts "Unknown command '#{command}'"
      puts ""
      help
    end

    private

    attr_reader :legacy_commands

    def initialize(*)
      super

      @legacy_commands = Bookbinder::Commands::Collection.new(colorized_streams, git)
    end

    def git
      @git ||= Ingest::GitAccessor.new
    end

    def colorized_streams
      @streams ||= {
        err: Streams::ColorizedStream.new(Colorizer::Colors.red, $stderr),
        out: $stdout,
        success: Streams::ColorizedStream.new(Colorizer::Colors.green, $stdout),
        warn: Streams::ColorizedStream.new(Colorizer::Colors.yellow, $stdout),
      }
    end
  end
end
