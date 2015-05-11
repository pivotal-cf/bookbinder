require_relative '../../../../lib/bookbinder/config/remote_bind_configuration'
require_relative '../../../../lib/bookbinder/configuration'

module Bookbinder
  module Config
    describe RemoteBindConfiguration do
      it "merges versioned sections into the config"

      it "raises an exception when there's an empty 'sections' specified in the remote config" do
        vcs = double('version control system')
        base_config = Configuration.new('book_repo' => 'foo', 'public_host' => 'bar', 'versions' => ['v1'])
        remote_config = RemoteBindConfiguration.new(vcs, base_config)
        allow(vcs).to receive(:read_file) { "---\nsections: " }
        expect { remote_config.to_h }.to raise_error(RemoteBindConfiguration::VersionUnsupportedError)
      end
    end
  end
end
