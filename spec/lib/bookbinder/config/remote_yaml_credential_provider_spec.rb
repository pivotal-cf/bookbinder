require_relative '../../../../lib/bookbinder/config/remote_yaml_credential_provider'

module Bookbinder
  module Config
    describe RemoteYamlCredentialProvider do
      it 'returns a hash of the credentials in credentials.yml' do
        version_control_system = double('vcs')

        provider = RemoteYamlCredentialProvider.new(
          double('logger').as_null_object,
          version_control_system
        )

        credentials = {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}

        allow(version_control_system).
          to receive(:read_file).
          with("credentials.yml", from_repo: "git@foobar.org:org-name/creds-repo") {
            credentials.to_yaml
          }

        expect(provider.credentials('git@foobar.org:org-name/creds-repo')).to eq(credentials)
      end

      it 'logs a processing message' do
        version_control_system = double('vcs', read_file: "")
        logger = double('logger')

        provider = RemoteYamlCredentialProvider.new(
          logger,
          version_control_system
        )

        expect(logger).to receive(:log).with("Processing #{ANSI.cyan { "git@ugly.url:who/cares" }}")
        provider.credentials("git@ugly.url:who/cares")
      end
    end
  end
end
