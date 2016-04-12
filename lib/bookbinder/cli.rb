require 'thor'

require_relative 'ingest/git_accessor'
require_relative 'streams/colorized_stream'
require_relative 'colorizer'
require_relative 'commands/collection'

module Bookbinder
  class CLI < Thor
    map '--version' => :version
    map '--help' => :help

    desc '--version', 'Print the version of bookbinder'
    def version
      gemspec = File.expand_path('../../../bookbinder.gemspec', __FILE__)
      say "bookbinder #{Gem::Specification::load(gemspec).version}"
    end

    desc '--help', 'Print this message'
    def help
      super
    end

    desc 'generate <book_name>', 'Generate a skeleton book that can be bound with "bookbinder bind"'
    def generate(book_name)
      legacy_commands.generate.run(book_name)
    end

    desc 'bind <local|remote> [--verbose] [--dita-flags=\"<dita-option>=<value>\"]', 'Bind the sections specified in config.yml from <local> or <remote> into the final_app directory'
    option :verbose, type: :boolean
    option 'dita-flags'
    def bind(source)
      legacy_commands.bind(source, options[:verbose], options['dita-flags'])
    end

    desc 'punch <git tag>', 'Apply the specified <git tag> to your book, sections, and layout repo'
    def punch(git_tag)
      legacy_commands.punch(git_tag)
    end

    desc 'update_local_doc_repos', 'Run `git pull` on all sections that exist at the same directory level as your book directory'
    def update_local_doc_repos
      legacy_commands.update_local_doc_repos
    end

    desc 'watch', 'Bind and serve a local book, watching for changes'
    def watch
      legacy_commands.watch
    end

    desc 'imprint <local|remote> [--verbose] [--dita-flags=\"<dita-option>=<value>\"]', 'Generate a PDF for a given book'
    option :verbose, type: :boolean
    option 'dita-flags'
    def imprint(source)
      legacy_commands.imprint(source, options[:verbose], options['dita-flags'])
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
