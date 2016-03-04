require_relative '../../lib/bookbinder/legacy/cli'
require_relative '../helpers/redirection'
require_relative '../helpers/use_fixture_repo'

describe "watching a book" do
  include Bookbinder::Redirection
  use_fixture_repo

  it "invokes middleman" do
    File.write('./middleman', 'exit 123')
    File.chmod(0700, './middleman')
    expect(run_watch).to eq(123)
  end

  def run_watch
    cli = Bookbinder::Legacy::Cli.new(double('vcs'))
    old_path = ENV['PATH']
    ENV['PATH'] = Dir.pwd
    swallow_stdout { cli.run("watch") }
  ensure
    ENV['PATH'] = old_path
  end
end
