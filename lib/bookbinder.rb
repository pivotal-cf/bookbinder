puts "Loading Fog..."
require 'fog'
puts "Loading tmpdir..."
require 'tmpdir'
puts "Loading ansi..."
require 'ansi'
puts "Loading Faraday..."
require 'faraday'
require 'faraday_middleware'
puts "Loading Octokit..."
require 'octokit'
puts "Loading Middleman..."
require 'middleman-core/cli'
require 'middleman-core/profiling'

require_relative 'bookbinder/shell_out'
require_relative 'bookbinder/bookbinder_logger'
require_relative 'bookbinder/repository'
require_relative 'bookbinder/doc_repo'
require_relative 'bookbinder/book'
require_relative 'bookbinder/spider'

require_relative 'bookbinder/green_build_repository'
require_relative 'bookbinder/pdf_generator'
require_relative 'bookbinder/middleman_runner'
require_relative 'bookbinder/publisher'
require_relative 'bookbinder/doc_repo_change_monitor'
require_relative 'bookbinder/pusher'
require_relative 'bookbinder/local_doc_repos_updater'
require_relative 'bookbinder/cli'

require_relative 'bookbinder/bookbinder_command'
require_relative 'bookbinder/commands/build_and_push_tarball'
require_relative 'bookbinder/commands/docs_repo_updated'
require_relative 'bookbinder/commands/publish'
require_relative 'bookbinder/commands/push_local_to_staging'
require_relative 'bookbinder/commands/push_to_prod'
require_relative 'bookbinder/commands/run_publish_ci'
require_relative 'bookbinder/commands/update_local_doc_repos'
require_relative 'bookbinder/commands/tag'

# Finds the project root for both spec & production
GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))