require_relative '../../../lib/bookbinder/cf_command_runner'
require_relative '../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe CfCommandRunner do
    let(:streams) { { out: StringIO.new, err: StringIO.new } }
    let(:sheller) { instance_double("Bookbinder::Sheller") }
    let(:credentials) { Bookbinder::Config::CfCredentials.new(config_hash, 'staging') }
    let(:cf) { CfCommandRunner.new(streams, sheller, credentials, trace_file) }
    let(:trace_file) { 'path/to/log' }
    let(:binary_path) { '/usr/local/bin/cf'}

    before do
      allow(sheller).to receive(:get_stdout).with("which cf") { binary_path }
    end

    def success
      double('success status code', success?: true)
    end

    def failure
      double('failure status code', success?: false)
    end

    def succeeds(cmd)
      allow(sheller).to receive(:run_command).with(cmd, streams) { success }
    end

    def fails(cmd)
      allow(sheller).to receive(:run_command).with(cmd, streams) { failure }
    end

    def expect_with_success(cmd)
      expect(sheller).to receive(:run_command).with(cmd, streams) { success }
    end

    def expect_with_failure(cmd)
      expect(sheller).to receive(:run_command).with(cmd, streams) { failure }
    end

    describe "obtaining a new app for a fresh deploy" do
      let(:config_hash) { { 'app_name' => 'mygreatapp' } }

      it "uses the app name from the credentials, and makes it blue" do
        expect(cf.new_app).to eq(Deploy::BlueGreenApp.new('mygreatapp-blue'))
      end
    end

    describe '#login' do
      let(:config_hash) do
        {
          'username' => 'username',
          'password' => 'password',
          'api_endpoint' => 'api.example.com',
          'organization' => 'my-org',
          'env' => {
            'staging' => {
              'space' => 'my-space',
              'host' => {
                'domain-name-one.io' => ['some-name', 'some-other-name'],
                'domain_name_two.io'=> ['madeup-name', 'some-madeup-name']
              }
            }
          }
        }
      end
      let(:username_regex) { /cf login -u 'username' -p 'password' -a 'api.example.com' -o 'my-org' -s 'my-space'$/ }

      context 'when the cf credentials provide a username and password' do
        it 'calls cf login' do
          expect_with_success(username_regex)
          cf.login
        end
      end

      context 'when the cf credentials do not provide a username and password' do
        before do
          config_hash.delete('username')
          config_hash.delete('password')
        end

        it 'calls cf login' do
          expect_with_success(/cf login  -a 'api.example.com' -o 'my-org' -s 'my-space'$/)
          cf.login
        end
      end

      context 'when the login fails' do
        it 'raises' do
          fails(username_regex)
          expect { cf.login }.to raise_error(/Could not log in/)
        end
      end

      context 'when the cf cli is not in the path' do
        it 'raises' do
          allow(sheller).to receive(:get_stdout).with("which cf") { '' }
          expect { cf.login }.to raise_error(/CF CLI could not be found/)
        end
      end
    end

    describe '#cf_routes_output' do
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
          'env' => {
            'staging' => {
              'host' => {
                'cfapps.io' => ['docs', 'docs-test']
              }
            }
          }
        }
      end

      before do
        allow(sheller).to receive(:get_stdout).
          with(/routes/) { routes_output }
      end

      it "only queries the API once" do
        expect(sheller).to receive(:get_stdout).with(/routes/).once
        cf.cf_routes_output
      end

      context 'when the cf command fails' do
        it 'raises' do
          allow(sheller).to receive(:get_stdout).with(/routes/) { "" }
          expect { cf.cf_routes_output }.to raise_error(/failure executing cf routes/)
        end
      end
    end

    describe '#start' do
      let(:config_hash) { {} }
      it 'calls cf start' do
        expect_with_success("#{binary_path} start my-app-name")
        cf.start('my-app-name')
      end
    end

    describe '#push' do
      let(:config_hash) { {} }
      let(:namespace) { 'namespace' }
      let(:build_number) { 'build-number' }

      it 'send the right args' do
        expect(sheller).to receive(:run_command) do |variables, command|
          expect(variables['CF_TRACE']).to eq(trace_file)
          expect(command).to match(/cf push my-app-name -b ruby_buildpack -s cflinuxfs2 --no-route -m 256M -i 3/)
          success
        end

        cf.push('my-app-name')
      end

      context 'when the command fails' do
        it 'raises' do
          allow(sheller).to receive(:run_command) { failure }
          expect { cf.push('my-app-name') }.to raise_error(/Could not deploy app to my-app-name/)
        end
      end
    end

    describe '#map_routes' do
      context 'when a single domain and host exists' do
        let(:config_hash) do
          {
            'env' => {
              'staging' => {
                'host' => {
                  'domain-one.io' => ['docs']
                }
              }
            }
          }
        end

        it "maps the route" do
          expect_with_success(/cf map-route my-app-name domain-one.io -n docs/)
          cf.map_routes('my-app-name')
        end

        context 'when mapping fails' do
          it 'raises an error' do
            fails(/cf map-route my-app-name domain-one.io -n docs/)
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs.domain-one.io to it./)
          end
        end
      end

      context 'when multiple domains with multiple routes exist' do
        let(:config_hash) do
          {
            'env' => {
              'staging' => {
                'host' => {
                  'domain-one.io' => ['docs-blue', 'docs-green'],
                  'domain-two.io'=> ['docs-orange']
                }
              }
            }
          }
        end

        it "maps the routes" do
          expect_with_success(/cf map-route my-app-name domain-one\.io -n docs-blue/)
          expect_with_success(/cf map-route my-app-name domain-one\.io -n docs-green/)
          expect_with_success(/cf map-route my-app-name domain-two\.io -n docs-orange/)
          cf.map_routes('my-app-name')
        end

        context 'when the first mapping fails' do
          it 'raises' do
            fails(/cf map-route my-app-name domain-one.io -n docs-blue/)
            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-blue.domain-one.io to it./)
          end
        end

        context 'when the command passes the first time and fails the second time' do
          it 'unmaps the first route and raises an error' do
            succeeds(/cf map-route my-app-name domain-one\.io -n docs-blue/)
            fails(/cf map-route my-app-name domain-one\.io -n docs-green/)
            expect_with_success(/cf unmap-route my-app-name domain-one.io -n docs-blue/)

            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-green.domain-one.io to it./)
          end
        end

        context 'when the command passes the first and second times and fails the third time' do
          let(:cf_map_route_blue_app_result) { true }
          let(:cf_map_route_green_app_result) { true }
          let(:cf_map_route_orange_app_result) { false }

          it 'unmaps the first and second routes and raises an error' do
            succeeds(/cf map-route my-app-name domain-one\.io -n docs-blue/)
            succeeds(/cf map-route my-app-name domain-one\.io -n docs-green/)
            fails(/cf map-route my-app-name domain-two\.io -n docs-orange/)
            expect_with_success(/cf unmap-route my-app-name domain-one.io -n docs-blue/)
            expect_with_success(/cf unmap-route my-app-name domain-one.io -n docs-green/)

            expect { cf.map_routes('my-app-name') }.to raise_error(/Deployed app to my-app-name but failed to map hostname docs-orange.domain-two.io to it./)
          end
        end
      end

      context 'when the host is an empty string' do
        let(:config_hash) do
          {
            'env' => {
              'staging' => {
                'host' => {
                  'domain-one.io' => [""]
                }
              }
            }
          }
        end

        it 'should run cf map-routes without the -n feature' do
          expect_with_success(/cf map-route my-app-name domain-one.io/)
          cf.map_routes('my-app-name')
        end
      end
    end

    describe '#unmap_routes' do
      let(:config_hash) do
        {
          'env' => {
            'staging' => {
              'host' => {
                'cfapps.io' => ['some-staging-host']
              }
            }
          }
        }
      end

      context 'when a single domain and route exists' do
        it "unmaps the route" do
          expect_with_success(/cf unmap-route my-app-name cfapps.io -n some-staging-host/)
          cf.unmap_routes('my-app-name')
        end

        context 'when unmap fails' do
          it 'raises an error' do
            fails(/cf unmap-route my-app-name cfapps.io -n some-staging-host/)
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-staging-host on my-app-name./)
          end
        end
      end

      context 'when multiple domains / routes exist' do
        let(:config_hash) do
          {
            'env' => {
              'staging' => {
                'host' => {
                  'some-staging-domain.io' => ['some-staging-host', 'some-other-staging-host'],
                  'madeup-staging-domain.io'=> ['some-madeup-host', 'another-madeup-host']
                }
              }
            }
          }
        end

        it 'unmaps all routes' do
          config_hash['env']['staging']['host'].each do |domain, hosts|
            hosts.each do |host|
              expect_with_success(/cf unmap-route my-app-name #{domain} -n #{host}/)
            end
          end
          cf.unmap_routes('my-app-name')
        end

        context 'when one unmap fails' do
          it 'immediately raises an error' do
            succeeds(/cf unmap-route my-app-name some-staging-domain\.io -n some-staging-host/)
            succeeds(/cf unmap-route my-app-name some-staging-domain\.io -n some-other-staging-host/)
            fails(/cf unmap-route my-app-name madeup-staging-domain\.io -n some-madeup-host/)
            expect { cf.unmap_routes('my-app-name') }.to raise_error(/Failed to unmap route some-madeup-host on my-app-name./)
          end
        end
      end

      context 'when the host is an empty string' do
        let(:config_hash) do
          {
            'env' => {
              'staging' => {
                'host' => {
                  'domain-one.io' => [""]
                }
              }
            }
          }
        end

        it 'should run cf unmap-routes without the -n feature' do
          expect_with_success(/cf unmap-route my-app-name domain-one.io$/)
          cf.unmap_routes('my-app-name')
        end
      end
    end

    describe '#takedown_old_target_app' do
      let(:config_hash) do
        {
          'env' => {
            'staging' => {
              'host' => {
                'some-staging-domain.io' => ['some-staging-host', 'some-other-staging-host']
              }
            }
          }
        }
      end

      before do
        expect(Kernel).to receive(:sleep).with(1).exactly(15).times
      end

      context 'when cf stop succeeds' do
        before do
          succeeds(/cf stop my-app-name$/)
        end

        it "unmaps the routes" do
          expect_with_success(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/)
          expect_with_success(/cf unmap-route my-app-name some-staging-domain.io -n some-other-staging-host/)
          cf.takedown_old_target_app('my-app-name')
        end

        context 'when unmapping a route fails' do
          it 'raises' do
            succeeds(/cf unmap-route my-app-name some-staging-domain.io -n some-staging-host/)
            fails(/cf unmap-route my-app-name some-staging-domain.io -n some-other-staging-host/)
            expect { cf.takedown_old_target_app('my-app-name') }.
              to raise_error(/Failed to unmap route some-other-staging-host on my-app-name/)
          end
        end
      end

      context 'when cf stop fails' do
        it 'raises' do
          fails(/cf stop/)
          expect { cf.takedown_old_target_app('my-app-name') }.to raise_error(/Failed to stop application my-app-name/)
        end
      end
    end
  end
end
