require 'spec_helper'

module Bookbinder
  describe CfCommandRunner do
    let(:logger) { NilLogger.new }
    let(:credentials) { Configuration::CfCredentials.new(config_hash, false) }
    let(:cf) { CfCommandRunner.new(logger, credentials, trace_file) }
    let(:trace_file) { 'path/to/log' }
    let (:binary_path_syscall ) { '/usr/local/bin/cf\n' }
    let (:binary_path) { '/usr/local/bin/cf'}

    before do
      CfCommandRunner.any_instance.stub(:`).and_return(binary_path_syscall)
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
            'staging_host' => 'http://host.example.com'
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
        let (:binary_path ) { '' }

        it 'raises' do
          CfCommandRunner.any_instance.stub(:`).and_return(binary_path)
          expect {
            cf.login
          }.to raise_error(/CF CLI could not be found/)
        end
      end

      context 'when the cf cli is in the path' do
        let (:binary_path_syscall ) { '/usr/local/bin/cf\n' }
        let (:binary_path) { '/usr/local/bin/cf'}

        it 'does not raise' do
          CfCommandRunner.any_instance.stub(:`).and_return(binary_path_syscall)
          allow(binary_path_syscall).to receive(:chomp!).and_return(binary_path)
          expect(Kernel).to receive(:system).with("#{binary_path} login -u 'username' -p 'password' -a 'api.example.com' -o 'my-org' -s 'my-space'").and_return(true)
          expect { cf.login }.to_not raise_error
        end
      end
    end

    describe '#apps' do
      let(:host1) { 'docs' }
      let(:host2) { 'docs-test' }
      let(:host3) { 'docs-new-route' }
      let(:hosts) { [host1, host2] }
      let(:too_many_hosts) { [host1, host2, host3] }
      let(:apps) { ['docs-green'] }
      let(:routes_output) do
        space = ' ' # for the editors that trim off trailing whitespace...
        <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

host                    domain                apps
no-cat-pictures         cfapps.io
less-cat-pictures       cfapps.io             cats #{space}
cat-pictures            cfapps.io             cats #{space}
#{host1}misleading      cfapps.io
#{host1}                cfapps.io             #{apps.join(', ')} #{space}
#{host2}misleading      cfapps.io
#{host2}                cfapps.io             #{apps.join(', ')} #{space}
more-cat-pictures       cfapps.io             many-cats, too-many-cats #{space}
OUTPUT
      end

      let(:config_hash) do
        {
            'staging_host' => hosts
        }
      end
      let(:command_success) { true }

      before do
        allow(Open3).to receive(:capture2).with(/routes/).and_return([routes_output, double(success?: command_success)])
      end

      context 'when there are multiple hosts with the same app' do
        it 'queries for apps for each host' do
          expect(cf).to receive(:apps_for_host).at_least(hosts.count).times
          cf.apps
        end

        it 'does not error out' do
          expect { cf.apps }.not_to raise_error
        end
      end

      context 'when a route in the creds is not yet mapped in the app' do
        let(:config_hash) do
          { 'staging_host' => too_many_hosts }
        end
        it 'it does not try to find the app for that route name' do
          expect(cf).to receive(:apps_for_host).exactly(hosts.count).times
          cf.apps
        end
      end
    end

    describe '#apps_for_host' do
      let(:host) { 'docs' }
      let(:apps) { ['docs-green'] }
      let(:routes_output) do
        space = ' ' # for the editors that trim off trailing whitespace...
        <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

host                    domain                apps
no-cat-pictures         cfapps.io
less-cat-pictures       cfapps.io             cats #{space}
cat-pictures            cfapps.io             cats #{space}
#{host}misleading       cfapps.io
#{host}                 cfapps.io             #{apps.join(', ')} #{space}
more-cat-pictures       cfapps.io             many-cats, too-many-cats #{space}
OUTPUT
      end

      let(:config_hash) do
        {
            'staging_host' => host
        }
      end
      let(:command_success) { true }

      before do
        allow(Open3).to receive(:capture2).with(/routes/).and_return([routes_output, double(success?: command_success)])
      end

      context 'when the host has one app' do
        it 'is that single app' do
          expect(cf.apps_for_host('docs')).to eq(apps)
        end
      end

      context 'when the host has multiple apps' do
        let(:apps) { ['docs-green', 'docs-blue'] }
        it 'is the first app' do
          expect(cf.apps_for_host('docs')).to eq(apps)
        end
      end

      context 'when the host has no apps' do
        let(:apps) { [] }
        it 'raises' do
          expect { cf.apps_for_host('docs') }.to raise_error(/no apps found/)
        end
      end

      context 'when the host is found' do
        it 'does not raise' do
          expect { cf.apps_for_host('docs') }.not_to raise_error
        end
      end

      context 'when the host is not found' do
        let(:routes_output) { '' }
        it 'raises' do
          expect { cf.apps_for_host('docs') }.to raise_error(/no routes found/)
        end
      end

      context 'when the command fails' do
        let(:command_success) { false }
        it 'raises' do
          expect { cf.apps_for_host('docs') }.to raise_error(/failure executing cf routes/)
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
      let(:command_success) { true }

      before do
        allow(Kernel).to receive(:system).and_return(command_success)
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
          expect(command).to match(/cf push my-app-name --no-route -m 256M -i 2/)
        end

        cf.push('my-app-name')
      end

      context 'when the command fails' do
        let(:command_success) { false }

        it 'raises' do
          expect { cf.push('my-app-name') }.to raise_error(/Could not deploy app to my-app-name/)
        end
      end

      context 'when the command passes' do
        let(:command_success) { true }

        it 'does not raise' do
          expect { cf.push('my-app-name') }.not_to raise_error
        end
      end
    end

    describe '#map_routes' do

      context 'when multiple host names are in provided' do
        let(:config_hash) { {'staging_host' => ['some-staging-host', 'some-other-staging-host']} }

        before do
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name cfapps.io -n some-staging-host/).and_return(first_command_success)
          allow(Kernel).to receive(:system).with(/cf map-route my-app-name cfapps.io -n some-other-staging-host/).and_return(second_command_success)
        end

        context 'when the first command fails' do
          let(:first_command_success) { false }
          let(:second_command_success) { false }
          it 'raises' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname some-staging-host.cfapps.io to it./)
          end
        end

        context 'when the first and second command passes' do
          let(:first_command_success) { true }
          let(:second_command_success) { true }
          it 'does not raise' do
            expect { cf.map_routes('my-app-name') }.not_to raise_error
          end
        end

        context 'when the command passes the first time and fails the second time' do
          let(:first_command_success) { true }
          let(:second_command_success) { false }
          it 'raises an error' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname some-other-staging-host.cfapps.io to it./)
          end
        end
      end

      context 'when one host name is provided' do
        let(:config_hash) { {'staging_host' => 'some-staging-host'} }

        before do
          expect(Kernel).to receive(:system).with(/cf map-route my-app-name cfapps.io -n some-staging-host/).and_return(command_success)
        end

        context 'when the command fails' do
          let(:command_success) { false }
          it 'raises' do
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname some-staging-host.cfapps.io to it./)
          end
        end

        context 'when the command passes' do
          let(:command_success) { true }
          it 'does not raise' do
            expect { cf.map_routes('my-app-name') }.not_to raise_error
          end
        end
      end
    end

    describe '#unmap_routes' do
      let(:config_hash) { {'staging_host' => 'some-staging-host'} }

      context 'when one route exists' do
        before do
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name cfapps.io -n some-staging-host/).and_return(command_success)
        end

        context 'when unmap fails' do
          let(:command_success) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route my-app-name on some-staging-host./)
          end
        end

        context 'when unmap succeeds' do
          let(:command_success) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end
      end

      context 'when multiple routes exist' do
        let(:config_hash) { {'staging_host' => ['some-staging-host', 'some-other-staging-host']} }
        before do
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name cfapps.io -n some-staging-host/).and_return(first_command_success)
          allow(Kernel).to receive(:system).with(/cf unmap-route my-app-name cfapps.io -n some-other-staging-host/).and_return(second_command_success)
        end

        context 'when the first command fails' do
          let(:first_command_success) { false }
          let(:second_command_success) { false }
          it 'raises' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route my-app-name on some-staging-host./)
          end
        end

        context 'when the first and second command passes' do
          let(:first_command_success) { true }
          let(:second_command_success) { true }
          it 'does not raise' do
            expect { cf.unmap_routes('my-app-name') }.not_to raise_error
          end
        end

        context 'when the command passes the first time and fails the second time' do
          let(:first_command_success) { true }
          let(:second_command_success) { false }
          it 'raises an error' do
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route my-app-name on some-other-staging-host./)
          end
        end
      end
    end

    describe '#takedown_old_target_app' do
      let(:config_hash) { {'staging_host' => 'some-staging-host'} }

      before do
        expect(Kernel).to receive(:sleep).with(1).exactly(15).times
        expect(Kernel).to receive(:system).with(/cf stop my-app-name$/).and_return(stop_command_success)
      end

      context 'when cf stop succeeds' do
        let(:stop_command_success) { true }

        before do
          expect(Kernel).to receive(:system).with(/cf unmap-route my-app-name cfapps.io -n some-staging-host/).and_return(unmap_command_success)
        end

        context 'when cf unmap-route succeeds' do
          let(:unmap_command_success) { true }

          it 'does not raise' do
            expect { cf.takedown_old_target_app('my-app-name') }.not_to raise_error
          end
        end

        context 'when cf unmap-route fails' do
          let(:unmap_command_success) { false }

          it 'raises' do
            expect { cf.takedown_old_target_app('my-app-name') }.to raise_error(/Failed to unmap route my-app-name on some-staging-host/)
          end
        end
      end

      context 'when cf stop fails' do
        let(:stop_command_success) { false }

        it 'raises' do
          expect { cf.takedown_old_target_app('my-app-name') }.to raise_error(/Failed to stop application my-app-name/)
        end
      end
    end
  end
end
