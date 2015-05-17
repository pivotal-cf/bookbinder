require_relative '../../../../lib/bookbinder/config/bind_config_factory'
require_relative '../../../../lib/bookbinder/config/remote_bind_configuration'
require_relative '../../../../lib/bookbinder/configuration'

module Bookbinder
  module Config
    describe RemoteBindConfiguration do
      it "merges versioned sections into the config" do
        vcs = double('version control system')

        base_config = Configuration.new('book_repo' => 'git@myplace.com:foo/bar',
                                        'public_host' => 'baz',
                                        'sections' => [{'repository' => {'name' => 'first/masterrepo'}}],
                                        'versions' => ['v1', 'v0.9'])

        fetcher = double('config fetcher', fetch_config: base_config)
        factory = BindConfigFactory.new(vcs, fetcher)

        allow(vcs).to receive(:read_file).with('config.yml', from_repo: "git@myplace.com:foo/bar", checkout: 'v1') {
          YAML.dump(
            'sections' => [
              {'repository' => {'name' => 'first/v1repo'}, 'directory' => 'foo'},
              {'repository' => {'name' => 'second/v1repo'}, 'directory' => 'bar'}
            ]
          )
        }

        allow(vcs).to receive(:read_file).with('config.yml', from_repo: "git@myplace.com:foo/bar", checkout: 'v0.9') {
          YAML.dump(
            'sections' => [
              {'repository' => {'name' => 'first/v0.9repo'}, 'directory' => 'foo'},
              {'repository' => {'name' => 'second/v0.9repo'}, 'directory' => 'bar'}
            ]
          )
        }

        expect(factory.produce('remote')).to eq(base_config.merge(
          'sections' => [
            {'repository' => {'name' => 'first/masterrepo'}},
            {'repository' => {'name' => 'first/v1repo', 'ref' => 'v1'}, 'directory' => 'v1/foo'},
            {'repository' => {'name' => 'second/v1repo', 'ref' => 'v1'}, 'directory' => 'v1/bar'},
            {'repository' => {'name' => 'first/v0.9repo', 'ref' => 'v0.9'}, 'directory' => 'v0.9/foo'},
            {'repository' => {'name' => 'second/v0.9repo', 'ref' => 'v0.9'}, 'directory' => 'v0.9/bar'},
          ]
        ))
      end

      it "permits use of 'github' as a source" do
        vcs = double('version control system')

        base_config = Configuration.new('book_repo' => 'git@myplace.com:foo/bar',
                                        'public_host' => 'baz',
                                        'sections' => [{'repository' => {'name' => 'first/masterrepo'}}],
                                        'versions' => ['v1'])

        fetcher = double('config fetcher', fetch_config: base_config)
        factory = BindConfigFactory.new(vcs, fetcher)

        allow(vcs).to receive(:read_file).with('config.yml', from_repo: "git@myplace.com:foo/bar", checkout: 'v1') {
          YAML.dump(
            'sections' => [
              {'repository' => {'name' => 'first/v1repo'}, 'directory' => 'foo'},
              {'repository' => {'name' => 'second/v1repo'}, 'directory' => 'bar'}
            ]
          )
        }

        expect(factory.produce('github')).to eq(base_config.merge(
          'sections' => [
            {'repository' => {'name' => 'first/masterrepo'}},
            {'repository' => {'name' => 'first/v1repo', 'ref' => 'v1'}, 'directory' => 'v1/foo'},
            {'repository' => {'name' => 'second/v1repo', 'ref' => 'v1'}, 'directory' => 'v1/bar'},
          ]
        ))
      end

      it "raises an exception when there's an empty 'sections' specified in the remote config" do
        vcs = double('version control system')
        base_config = Configuration.new('book_repo' => 'foo', 'public_host' => 'bar', 'versions' => ['v1'])
        remote_config = RemoteBindConfiguration.new(vcs, base_config)
        allow(vcs).to receive(:read_file) { "---\nsections: " }
        expect { remote_config.fetch }.to raise_error(RemoteBindConfiguration::VersionUnsupportedError)
      end
    end
  end
end
