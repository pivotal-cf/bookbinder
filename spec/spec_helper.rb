require 'fileutils'
require 'webmock/rspec'
require_relative '../lib/bookbinder'
require_relative '../template_app/app.rb'
require_relative 'fixtures/repo_fixture'
require_relative 'fixtures/git_object_fixture'

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
    Bookbinder::Pusher.any_instance.stub(:push) unless self.class.metadata[:enable_pusher]

    allow(Bookbinder::Section).to receive(:store).and_return({})
  end
end

class SpecGitAccessor
  def self.clone(repository, name, options = {})
    local_repo_dir = File.join(GEM_ROOT, 'spec', 'fixtures', 'repositories')
    destination = File.join(options.fetch(:path, ''), name)

    FileUtils.mkdir_p(destination)
    FileUtils.cp_r(File.join(local_repo_dir, File.basename(repository), '.'), destination)
    new(repository, destination)
  end

  def initialize(repository, path)
    @repository = repository
    @path = path
  end

  def checkout(ref)
    @ref = ref
    local_repo_dir = File.join(GEM_ROOT, 'spec', 'fixtures', 'repositories')
    # To simulate a git checkout, remove everything first instead of copying over the top.
    FileUtils.rm_rf(Dir.glob("#{@path}/*"))
    FileUtils.cp_r(File.join(local_repo_dir, "#{File.basename(@repository)}-ref-#{ref}", '.'), @path)
  end

  def log
    SpecGitLog.new(self.clone, @ref)
  end

  def gtree(ref)
    SpecGitGtree.new
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
