require_relative '../../../lib/bookbinder/app_fetcher'

module Bookbinder
  describe AppFetcher do
    describe 'retrieving apps' do
      let(:routes_output) do
        eol_space = ' '
        <<OUTPUT
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space       host                    domain                apps
my-space    no-cat-pictures         cfapps.io
my-space    less-cat-pictures       cfapps.io             cats #{eol_space}
my-space    cat-pictures            cfapps.io             cats #{eol_space}
my-space    docsmisleading          cfapps.io
my-space    docs                    cfapps.io             docs-green #{eol_space}
my-space    docs-testmisleading     cfapps.io
my-space    docs-test               cfapps.io             docs-green,docs-blue #{eol_space}
my-space    more-cat-pictures       cfapps.io             many-cats, too-many-cats #{eol_space}
OUTPUT
      end

      let(:routes_to_search) { [['cfapps.io', 'docs']] }
      let(:cf_command_runner) { double 'cf_command_runner' }
      let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }

      before do
        allow(cf_command_runner).to receive(:cf_routes_output).and_return(routes_output)
      end

      it 'returns the correct app' do
        expect(subject.fetch_current_app).to eq(BlueGreenApp.new('docs-green'))
      end

      it 'only queries the API once' do
        expect(cf_command_runner).to receive(:cf_routes_output).once
        subject.fetch_current_app
      end

      context 'when there are no apps' do
        let(:routes_output) do
          eol_space = ' '
          <<OUTPUT
  Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space         host                    domain                apps
cool-space    docs                    cfapps.io             #{eol_space}
OUTPUT
        end

        it 'returns nil' do
          expect(subject.fetch_current_app).to be_nil
        end
      end

      context 'when the host is not found' do
        let(:routes_output) do
          eol_space = ' '
          <<OUTPUT
  Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space           host                    domain                apps
cool-space      foo                     cfapps.io             fantastic-app #{eol_space}
OUTPUT
        end

        it 'returns nil' do
          expect(subject.fetch_current_app).to be_nil
        end
      end

      context "when there are spaces in between app names" do
        let(:routes_to_search) { [['cfapps.io', 'more-cat-pictures']] }

        it "returns app names with stripped spaces" do
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('many-cats'))
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
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('docs-green'))
        end
      end
    end
  end
end
