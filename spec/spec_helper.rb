require 'webmock/rspec'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    directory = File.join(tmpdir, name)
    FileUtils.mkdir directory
    directory
  end

  let(:tmpdir) { Dir.mktmpdir }
end

require_relative '../lib/bookbinder'

require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'middleman-core/load_paths'

require_relative 'fixtures/markdown_repo_fixture'

RSpec.configure do |config|

  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil
  end

  config.before do
    BookbinderLogger.stub(:log) {  }
  end
end



