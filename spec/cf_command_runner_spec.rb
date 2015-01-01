require 'spec_helper'

module Bookbinder
  describe CfCommandRunner do
    let(:logger) { NilLogger.new }
    let(:credentials) { Configuration::CfCredentials.new(config_hash, false) }
    let(:cf) { CfCommandRunner.new(logger, credentials, trace_file) }
    let(:trace_file) { 'path/to/log' }
    let(:binary_path_syscall ) { '/usr/local/bin/cf\n' }
    let(:binary_path) { '/usr/local/bin/cf'}

    before do
      allow_any_instance_of(CfCommandRunner).to receive(:`).and_return(binary_path_syscall)
      allow(binary_path_syscall).to receive(:chomp!).and_return(binary_path)
    end

    describe '#login' do
      let(:config_hash) do
        {
            'username' => 'username',
            'password' => 'password',
            'api_endpoint' => 'api.example.com',
            'organization' => 'my-org',
            'staging_space' => 'my-space',
            'staging_host' => {
              'domain-name-one.io' => ['some-name', 'some-other-name'],
              'domain_name_two.io'=> ['madeup-name', 'some-madeup-name']
            }
        }
      end
      let(:username_regex) { /cf login -u 'username' -p 'password' -a 'api.example.com' -o 'my-org' -s 'my-space'$/ }

      context 'when the cf credentials provide a username and password' do
        it 'calls cf login' do
          expect(Kernel).to receive(:system).with(username_regex).and_return(true)
          expect { cf.login }.to_not raise_error
        end
      end

      context 'when the cf credentials do not provide a username and password' do
        before do
          config_hash.delete('username')
          config_hash.delete('password')
        end

        it 'calls cf login' do
          expect(Kernel).to receive(:system).with(/cf login  -a 'api.example.com' -o 'my-org' -s 'my-space'$/).and_return(true)
          expect { cf.login }.to_not raise_error
        end
      end

      context 'when the login fails' do
        it 'raises' do
          expect(Kernel).to receive(:system).with(username_regex).and_return(false)
          expect {
            cf.login
          }.to raise_error(/Could not log in/)
        end
      end

      context 'when the cf cli is not in the path' do
        let(:binary_path ) { '' }

        it 'raises' do
          allow_any_instance_of(CfCommandRunner).to receive(:`).and_return(binary_path)
          expect { cf.login }.to raise_error(/CF CLI could not be found/)
        end
      end

      context 'when the cf cli is in the path' do
        let(:binary_path_syscall ) { '/usr/local/bin/cf\n' }
        let(:binary_path) { '/usr/local/bin/cf'}

        it 'does not raise' do
          allow_any_instance_of(CfCommandRunner).to receive(:`).and_return(binary_path_syscall)
          allow(binary_path_syscall).to receive(:chomp!).and_return(binary_path)
          expect(Kernel).to receive(:system).with("#{binary_path} login -u 'username' -p 'password' -a 'api.example.com' -o 'my-org' -s 'my-space'").and_return(true)
          expect { cf.login }.to_not raise_error
        end
      end
    end

    describe '#apps' do
      let(:routes_output) do
        eol_space = ' '
        <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

host                    domain                apps
no-cat-pictures         cfapps.io
less-cat-pictures       cfapps.io             cats #{eol_space}
cat-pictures            cfapps.io             cats #{eol_space}
docsmisleading          cfapps.io
docs                    cfapps.io             docs-green #{eol_space}
docs-testmisleading     cfapps.io
docs-test               cfapps.io             docs-green,docs-blue #{eol_space}
more-cat-pictures       cfapps.io             many-cats, too-many-cats #{eol_space}
OUTPUT
      end

      let(:config_hash) do
        {
          'staging_host' => {
            'cfapps.io' => ['docs', 'docs-test']
          }
        }
      end

      before do
        allow(Open3).to receive(:capture2).
          with(/routes/).
          and_return([routes_output,
                      double(success?: true)])
      end

      it 'returns the app sets for multiple hosts' do
        expect(cf.apps).to eq([%w(docs-green), %w(docs-green docs-blue)])
      end

      it "only queries the API once" do
        expect(Open3).to receive(:capture2).once
        cf.apps
      end

      context "when there are no apps" do
        let(:routes_output) do
          eol_space = ' '
          <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

host                    domain                apps
docs                    cfapps.io             #{eol_space}
OUTPUT
        end

        it "raises an exception" do
          expect { cf.apps }.to raise_error(/no apps found/)
        end
      end

      context 'when the host is not found' do
        let(:routes_output) do
          eol_space = ' '
          <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

host                    domain                apps
foo                     cfapps.io             fantastic-app #{eol_space}
OUTPUT
        end

        it 'raises' do
          expect { cf.apps }.to raise_error(/cannot find currently deployed app/)
        end
      end

      context "when there are spaces in between app names" do
        let(:config_hash) do
          {
            'staging_host' => {
              'cfapps.io' => ['more-cat-pictures']
            }
          }
        end

        it "returns app names with stripped spaces" do
          expect(cf.apps).to eq([%w(many-cats too-many-cats)])
        end
      end

      context 'when a route in the creds is not yet mapped in the app' do
        let(:config_hash) do
          {
            'staging_host' => {
              'cfapps.io' => %w(docs docs-test docs-new-route)
            }
          }
        end

        it "returns the apps for the mapped routes" do
          expect(cf.apps).to eq([%w(docs-green), %w(docs-green docs-blue)])
        end
      end

      context 'when the cf command fails' do
        it 'raises' do
          allow(Open3).to receive(:capture2).
            with(/routes/).
            and_return(['unparsed output',
                        double(success?: false)])
          expect { cf.apps }.to raise_error(/failure executing cf routes/)
        end
      end
    end

    describe '#start' do
      let(:config_hash) { {} }
      it 'calls cf start' do
        expect(Kernel).to receive(:system).with(/cf start my-app-name/)
        cf.start('my-app-name')
      end
    end

    describe '#push' do
      let(:config_hash) { {} }
      let(:namespace) { 'namespace' }
      let(:build_number) { 'build-number' }
      let(:cf_push_command_result) { true }

      before do
        allow(Kernel).to receive(:system).and_return(cf_push_command_result)
      end

      it 'sets the trace file environment variable for system calls' do
        expect(Kernel).to receive(:system) do |variables, command|
          expect(variables['CF_TRACE']).to eq(trace_file)
          expect(command).to match(/push/)
        end

        cf.push('my-app-name')
      end

      it 'send the right args' do
        expect(Kernel).to receive(:system) do |variables, command|
          expect(command).to match(/cf push my-app-name --no-route -m 256M -i 3/)
        end

        cf.push('my-app-name')
      end

      context 'when the command fails' do
        let(:cf_push_command_result) { false }

        it 'raises' do
          expect { cf.push('my-app-name') }.to raise_error(/Could not deploy app to my-app-name/)
        end
      end

      context 'when the command passes' do
        let(:cf_push_command_result) { true }

        it 'does not raise' do
          expect { cf.push('my-app-name') }.not_to raise_error
        end
      end
    end

    describe '#map_routes' do
      context 'when a single domain and route exist' do
        let(:config_hash) { { 'staging_host' => { 'domain-one.io' => ['docs'] } } }

        before do
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name domain-one.io -n docs/).and_return(cf_map_route_command_result)
        end

        context 'when mapping fails' do
          let(:cf_map_route_command_result) { false }
          it 'raises an error' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs.domain-one.io to it./)
          end
        end

        context 'when mapping succeeds' do
          let(:cf_map_route_command_result) { true }
          it 'does not raise' do
            expect { cf.map_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when multiple domains with multiple routes exist' do
        let(:config_hash) do
          { 'staging_host'=>
              { 'domain-one.io' => ['docs-blue', 'docs-green'],
                'domain-two.io'=> ['docs-orange'] }
          }
        end

        before do
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name domain-one.io -n docs-blue/).and_return(cf_map_route_blue_app_result)
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name domain-one.io -n docs-green/).and_return(cf_map_route_green_app_result)
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name domain-two.io -n docs/).and_return(cf_map_route_orange_app_result)
        end

        context 'when the first mapping fails' do
          let(:cf_map_route_blue_app_result) { false }
          let(:cf_map_route_green_app_result) { false }
          let(:cf_map_route_orange_app_result) { false }
          it 'raises' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-blue.domain-one.io to it./)
          end
        end

        context 'when the first, second, and third command passes' do
          let(:cf_map_route_blue_app_result) { true }
          let(:cf_map_route_green_app_result) { true }
          let(:cf_map_route_orange_app_result) { true }
          it 'does not raise' do
            expect { cf.map_routes('my-app-name') }.not_to raise_error
          end
        end

        context 'when the command passes the first time and fails the second time' do
          let(:cf_map_route_blue_app_result) { true }
          let(:cf_map_route_green_app_result) { false }
          let(:cf_map_route_orange_app_result) { true }
          it 'unmaps the first route and raises an error' do
            expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name domain-one.io -n docs-blue/).and_return(cf_map_route_blue_app_result)

            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-green.domain-one.io to it./)
          end
        end

        context 'when the command passes the first and second times and fails the third time' do
          let(:cf_map_route_blue_app_result) { true }
          let(:cf_map_route_green_app_result) { true }
          let(:cf_map_route_orange_app_result) { false }

          it 'unmaps the first and second routes and raises an error' do
            expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name domain-one.io -n docs-blue/).and_return(true)
            expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name domain-one.io -n docs-green/).and_return(true)

            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-orange.domain-two.io to it./)
          end
        end
      end

      context 'when one host name is provided' do
        let(:config_hash) { { 'staging_host'=> { 'cfapps.io' => ['some-staging-host'] } } }

        before do
          expect(Kernel).to receive(:system).with(/cf map-route my-app-name cfapps.io -n some-staging-host/).and_return(some_staging_host_map_route_command_result)
        end

        context 'when the command fails' do
          let(:some_staging_host_map_route_command_result) { false }
          it 'raises' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname some-staging-host.cfapps.io to it./)
          end
        end

        context 'when the command passes' do
          let(:some_staging_host_map_route_command_result) { true }
          it 'does not raise' do
            expect { cf.map_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when the host is an empty string' do
        let(:config_hash) { { 'staging_host' => { 'domain-one.io' => [""] } } }
        let(:cf_map_route_command_result) { true }

        before do
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name domain-one.io/).and_return(cf_map_route_command_result)
        end

        it 'should run cf map-routes without the -n feature' do
          expect(Kernel).to receive(:system).with(/cf map-route my-app-name domain-one.io/)

          cf.map_routes('my-app-name')
        end
      end
    end

    describe '#unmap_routes' do
      let(:config_hash) { { 'staging_host'=> { 'cfapps.io' => ['some-staging-host'] } } }

      context 'when a single domain and route exists' do
        before do
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name cfapps.io -n some-staging-host/).and_return(some_staging_host_unmap_route_command_result)
        end

        context 'when unmap fails' do
          let(:some_staging_host_unmap_route_command_result) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-staging-host on my-app-name./)
          end
        end

        context 'when unmap succeeds' do
          let(:some_staging_host_unmap_route_command_result) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when multiple routes exist' do
        let(:config_hash) do
          { 'staging_host' => { 'some-staging-domain.io' => ['some-staging-host', 'some-other-staging-host'] } }
        end

        before do
          allow(Kernel).to receive(:system).
            with(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/).
            and_return(some_staging_host_unmap_route_command_result)
          allow(Kernel).to receive(:system).
            with(/cf unmap-route my-app-name some-staging-domain.io -n some-other-staging-host/).
            and_return(some_other_staging_host_unmap_route_command_result)
        end

        context 'when the first command fails' do
          let(:some_staging_host_unmap_route_command_result) { false }
          let(:some_other_staging_host_unmap_route_command_result) { false }
          it 'raises' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-staging-host on my-app-name./)
          end
        end

        context 'when the command passes the first time and fails the second time' do
          let(:some_staging_host_unmap_route_command_result) { true }
          let(:some_other_staging_host_unmap_route_command_result) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-other-staging-host on my-app-name./)
          end
        end

        context 'when the first and second command passes' do
          let(:some_staging_host_unmap_route_command_result) { true }
          let(:some_other_staging_host_unmap_route_command_result) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when multiple domains exist' do
        let(:config_hash) do
          {
              'staging_host' => {
                  'some-staging-domain.io' => ['some-staging-host'],
                  'madeup-staging-domain.io'=> ['some-madeup-host']
              }
          }
        end

        before do
          allow(Kernel).to receive(:system).
            with(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/).
            and_return(some_staging_host_unmap_route_command_result)
          allow(Kernel).to receive(:system).
            with(/cf unmap-route my-app-name madeup-staging-domain.io -n some-madeup-host/).
            and_return(some_madeup_host_unmap_route_command_result)
        end

        context 'when the first domain unmap fails' do
          let(:some_staging_host_unmap_route_command_result) { false }
          let(:some_madeup_host_unmap_route_command_result) { false }
          it 'raises' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-staging-host on my-app-name./)
          end
        end

        context 'when the second domain unmap fails' do
          let(:some_staging_host_unmap_route_command_result) { true }
          let(:some_madeup_host_unmap_route_command_result) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-madeup-host on my-app-name./)
          end
        end

        context 'when both domain unmaps succeed' do
          let(:some_staging_host_unmap_route_command_result) { true }
          let(:some_madeup_host_unmap_route_command_result) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when multiple domains with multiple routes exist' do
        let(:some_staging_host_unmap_route_command_result)  { true }
        let(:some_other_staging_host_unmap_route_command_result) { true }
        let(:some_madeup_host_unmap_route_command_result)  { true }
        let(:config_hash) do
          {
              'staging_host' => {
                  'some-staging-domain.io' => ['some-staging-host', 'some-other-staging-host'],
                  'madeup-staging-domain.io'=> ['some-madeup-host', 'another-madeup-host']
              }
          }
        end

        before do
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/).
            and_return(some_staging_host_unmap_route_command_result)
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name some-staging-domain.io -n some-other-staging-host/).
            and_return(some_other_staging_host_unmap_route_command_result)
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name madeup-staging-domain.io -n some-madeup-host/).
            and_return(some_madeup_host_unmap_route_command_result)
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name madeup-staging-domain.io -n another-madeup-host/).
            and_return(another_madeup_host_unmap_route_command_result)
        end

        context 'when all the routes unmap successfully' do
          let(:another_madeup_host_unmap_route_command_result) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end

        context 'when one unmap fails' do
          let(:another_madeup_host_unmap_route_command_result) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route another-madeup-host on my-app-name./)
          end
        end

        context 'when multiple unmappings fail' do
          let(:some_madeup_host_unmap_route_command_result) { false }
          let(:another_madeup_host_unmap_route_command_result) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-madeup-host on my-app-name./)
          end
        end
      end

      context 'when the host is an empty string' do
        let(:config_hash) { { 'staging_host' => { 'domain-one.io' => [""] } } }
        let(:some_staging_host_unmap_route_command_result) { true }

        before do
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name domain-one.io/).and_return(some_staging_host_unmap_route_command_result)
        end

        it 'should run cf unmap-routes without the -n feature' do
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name domain-one.io/)

          cf.unmap_routes('my-app-name')
        end
      end
    end

    describe '#takedown_old_target_app' do
      let(:config_hash) { { 'staging_host' => { 'some-staging-domain.io' => ['some-staging-host', 'some-other-staging-host'] } } }

      before do
        expect(Kernel).to receive(:sleep).with(1).exactly(15).times
        expect(Kernel).to receive(:system).with(/cf stop my-app-name$/).and_return(stop_app_command_result)
      end

      context 'when cf stop succeeds' do
        let(:stop_app_command_result) { true }

        before do
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/).and_return(unmap_some_staging_host_result)
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name some-staging-domain.io -n some-other-staging-host/).and_return(unmap_some_other_staging_host_result)
        end

        context 'when cf unmap-route succeeds' do
          let(:unmap_some_staging_host_result) { true }
          let(:unmap_some_other_staging_host_result) { true }

          it 'does not raise' do
            expect { cf.takedown_old_target_app('my-app-name') }.not_to raise_error
          end
        end

        context 'when cf unmap-route fails' do
          let(:unmap_some_staging_host_result) { true }
          let(:unmap_some_other_staging_host_result) { false }

          it 'raises' do
            expect { cf.takedown_old_target_app('my-app-name') }.to raise_error(/Failed to unmap route some-other-staging-host on my-app-name/)
          end
        end
      end

      context 'when cf stop fails' do
        let(:stop_app_command_result) { false }

        it 'raises' do
          expect { cf.takedown_old_target_app('my-app-name') }.to raise_error(/Failed to stop application my-app-name/)
        end
      end
    end
  end
end
