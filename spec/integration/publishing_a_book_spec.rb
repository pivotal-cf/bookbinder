require 'spec_helper'

describe 'generating a book' do
  include_context 'tmp_dirs'

  around_with_fixture_repo &:run

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  it 'provides the production host to the ERB templates' do
    pending 'Revisit when publishing locally no longer accesses GitHub.'
    silence_io_streams do
      `#{GEM_ROOT}/bin/bookbinder publish local`
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

    it 'uses the provided layout' do
      pending 'Revisit when publishing locally no longer accesses GitHub.'
      silence_io_streams do
        `#{GEM_ROOT}/bin/bookbinder publish local`
      end

      index = File.read File.join('final_app', 'public', 'index.html')
      expect(index).to include('This is an alternate layout file.')
    end
  end
end
