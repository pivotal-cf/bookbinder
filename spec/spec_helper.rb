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

require_relative 'fixtures/markdown_repo_fixture'

RSpec.configure do |config|
  config.before do
    BookbinderLogger.stub(:log) {  }
  end
end



