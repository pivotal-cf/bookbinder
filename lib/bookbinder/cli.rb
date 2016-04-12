require 'thor'
require 'ansi/code'

require_relative 'ingest/git_accessor'
require_relative 'legacy/cli'

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
      run_legacy_cli('generate', book_name)
    end

    desc 'build_and_push_tarball', 'Create a tarball from the final_app directory and push to the S3 bucket specified in your credentials.yml'
    def build_and_push_tarball
      print_deploy_deprecation_message
      run_legacy_cli('build_and_push_tarball')
    end

    desc 'bind <local|remote> [--verbose] [--dita-flags=\"<dita-option>=<value>\"]', 'Bind the sections specified in config.yml from <local> or <remote> into the final_app directory'
    option :verbose, type: :boolean
    option 'dita-flags'
    def bind(source)
      args = ['bind', source]
      args << '--verbose' if options[:verbose]
      args << "--dita-flags=\\\"#{options['dita-flags']}\\\""
      run_legacy_cli(*args)
    end

    desc 'push_local_to <environment>', 'Push the contents of final_app to the specified environment using the credentials.yml'
    def push_local_to(environment)
      print_deploy_deprecation_message
      run_legacy_cli('push_local_to', environment)
    end

    desc 'push_to_prod [build_#]', 'Push latest or <build_#> from your S3 bucket to the production host specified in credentials.yml'
    def push_to_prod(build_num=nil)
      print_deploy_deprecation_message
      args = ['push_to_prod', build_num].compact
      run_legacy_cli(*args)
    end

    desc 'run_publish_ci', 'Run publish, push_local_to staging, and build_and_push_tarball for CI purposes'
    def run_publish_ci
      print_deploy_deprecation_message
      run_legacy_cli('run_publish_ci')
    end

    desc 'punch <git tag>', 'Apply the specified <git tag> to your book, sections, and layout repo'
    def punch(git_tag)
      run_legacy_cli('punch', git_tag)
    end

    desc 'update_local_doc_repos', 'Run `git pull` on all sections that exist at the same directory level as your book directory'
    def update_local_doc_repos
      run_legacy_cli('update_local_doc_repos')
    end

    desc 'watch', 'Bind and serve a local book, watching for changes'
    def watch
      run_legacy_cli('watch')
    end

    desc 'imprint <local|remote> [--verbose] [--dita-flags=\"<dita-option>=<value>\"]', 'Generate a PDF for a given book'
    option :verbose, type: :boolean
    option 'dita-flags'
    def imprint(source)
      args = ['imprint', source]
      args << '--verbose' if options[:verbose]
      args << "--dita-flags=\\\"#{options['dita-flags']}\\\""
      run_legacy_cli(*args)
    end

    private

    attr_reader :legacy_cli

    def initialize(*)
      super

      @legacy_cli = Legacy::Cli.new(Ingest::GitAccessor.new)
    end

    def run_legacy_cli(*args)
      status = legacy_cli.run(args)
      exit status unless status.zero?
    end

    def print_deploy_deprecation_message
      message = ANSI.red do
        <<-EOM

DEPRECATED: In a future version Bookbinder will no longer deploy to Cloud Foundry
            The appropriate Concourse pipeline should be doing all deploys going forward.

        EOM
      end

      puts message
    end
  end
end
