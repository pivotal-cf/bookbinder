require 'fileutils'
require 'webmock/rspec'
require_relative '../lib/bookbinder'
require_relative '../template_app/app.rb'
require_relative 'fixtures/repo_fixture'
require_relative 'fixtures/git_object_fixture'

include Bookbinder::DirectoryHelperMethods

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'helpers/*'))].each { |file| require_relative file }

RSpec.configure do |config|
  config.include Bookbinder::SpecHelperMethods

  config.order = 'random'
  config.color = true

  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil

    #the Github API token must be in the ENV or tests will fail.
    ENV['GITHUB_API_TOKEN'] = 'foo'
  end

  config.before do
    allow_any_instance_of(Bookbinder::Pusher).to receive(:push) unless self.class.metadata[:enable_pusher]

    allow(Bookbinder::Section).to receive(:store).and_return({})
  end

  config.mock_with :rspec do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end

class SpecGitLog
  def initialize(base, ref, count = 5)
    @base = base
    @count = count
    @ref = ref
  end

  def map
    ["#{@ref}"]
  end
end

class SpecGitGtree

  def blobs
    {}
  end

  def subtrees
    []
  end
end
