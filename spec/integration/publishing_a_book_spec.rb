require 'yaml'

require_relative '../helpers/tmp_dirs'
require_relative '../helpers/expectations'
require_relative '../helpers/middleman'

describe 'generating a book' do
  include Bookbinder::SpecHelperMethods

  include_context 'tmp_dirs'

  around_with_fixture_repo &:run

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  let(:gem_root) { File.expand_path('../../../', __FILE__) }

  it 'provides the production host to the ERB templates', integration: true do
    #pending 'Revisit when publishing locally no longer accesses GitHub.'
    silence_io_streams do
      `#{gem_root}/bin/bookbinder publish local`
    end

    index = File.read File.join('final_app', 'public', 'index.html')
    expect(index).to include('My production host is: docs.example.com')
  end

  context 'when a layout_repo is provided' do
    let(:section) do
<<YAML
- repository:
    name: fantastic/dogs-repo
    ref: 'dog-sha'
  directory: dogs
  subnav_template: dogs
YAML
    end

    before do
      config = YAML.load(File.read('./config.yml'))
      config.delete('cred_repo')
      config['sections'] = YAML.load(section)
      config['layout_repo'] = 'fantastic-org/layout-repo'
      File.write('./config.yml', config.to_yaml)
    end

    it 'uses the provided layout', integration: true do
      silence_io_streams do
        `#{gem_root}/bin/bookbinder publish local`
      end

      index = File.read File.join('final_app', 'public', 'index.html')
      expect(index).to include('This is an alternate layout file.')
    end
  end
end
