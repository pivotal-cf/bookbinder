require 'webmock/rspec'
require_relative '../lib/bookbinder'
require_relative '../template_app/app.rb'
require_relative 'fixtures/repo_fixture'
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'helpers/*'))].each { |file| require_relative file }

RSpec.configure do |config|
  config.include SpecHelperMethods

  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil

    #the Github API token must be in the ENV or tests will fail.
    ENV['GITHUB_API_TOKEN'] = 'foo'
  end

  config.before do
    Pusher.any_instance.stub(:push) unless self.class.metadata[:enable_pusher]

    allow(Section).to receive(:store).and_return({})
  end
end
