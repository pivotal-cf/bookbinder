require 'yaml'

require_relative '../helpers/use_fixture_repo'
require_relative '../helpers/redirection'

describe 'binding a book locally' do
  include Bookbinder::Redirection

  use_fixture_repo

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  let(:gem_root) { File.expand_path('../../../', __FILE__) }

  it 'provides the production host to the ERB templates' do
    swallow_stdout do
      `#{gem_root}/install_bin/bookbinder bind local`
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
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      expect(Pathname(File.join('final_app', 'public', 'cake.html'))).to exist
    end

    it 'prefers local layout files' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      index = File.read File.join('final_app', 'public', 'index.html')
      expect(index).to include('I come from the source layout.')
    end

    it 'compiles stylesheets files' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      expect(Pathname(File.join('final_app', 'public', 'stylesheets', 'book-styles.css'))).to exist
      expect(Pathname(File.join('final_app', 'public', 'stylesheets', 'fab-styles.css'))).to exist
    end

    it 'includes images' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      index = File.read File.join('final_app', 'public', 'dogs', 'index.html')
      expect(index).to include('<p><img src="images/breeds.png" /></p>')
    end
  end

  context 'when subnavs are specified in config.yml' do
    let(:section) do
<<YAML
- repository:
    name: fantastic/dogs-repo
    ref: 'dog-sha'
  directory: dogs
  subnav_name: doggies
- repository:
    name: fantastic/my-docs-repo
  subnav_name: doctastic
YAML
    end

    let(:subnav) do
<<YAML
- name: doggies
  topics:
  - title: First pug
    base_path: dogs/pugs
    toc_path: index
  - title: Second greyhound
    base_path: dogs/greyhounds
    toc_path: index
- name: doctastic
  topics:
  - title: Wordilicious
    base_path: my-docs-repo
    toc_path: index
YAML
    end

    before do
      config = YAML.load(File.read('./config.yml'))
      config.delete('cred_repo')
      config['sections'] = YAML.load(section)
      config['subnavs'] = YAML.load(subnav)
      File.write('./config.yml', config.to_yaml)
    end

    it 'includes titles from config in the subnav for generated html' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      expect(Pathname(File.join('final_app', 'public', 'subnavs', 'doggies-props.json'))).to exist
      expect(Pathname(File.join('final_app', 'public', 'subnavs', 'doctastic-props.json'))).to exist

      index_one = File.read File.join('final_app', 'public', 'dogs', 'index.html')
      expect(index_one).to include('<div class="nav-content" data-props-location="doggies-props.json">I am the default subnav!</div>')

      index_two = File.read File.join('final_app', 'public', 'my-docs-repo', 'index.html')
      expect(index_two).to include('<div class="nav-content" data-props-location="doctastic-props.json">I am the default subnav!</div>')
    end
  end
end
