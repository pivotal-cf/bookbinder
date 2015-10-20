require 'json'
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
    toc_path: dogs/pugs/index
  - title: Second greyhound
    toc_path: dogs/greyhounds/index
- name: doctastic
  topics:
  - title: Wordilicious
    toc_path: my-docs-repo/index
YAML
    end

    before do
      config = YAML.load(File.read('./config.yml'))
      config.delete('cred_repo')
      config['sections'] = YAML.load(section)
      config['subnavs'] = YAML.load(subnav)
      File.write('./config.yml', config.to_yaml)
    end

    it 'generates nav html with json props file' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      expect(Pathname(File.join('final_app', 'public', 'subnavs', 'doggies-props.json'))).to exist
      expect(Pathname(File.join('final_app', 'public', 'subnavs', 'doctastic-props.json'))).to exist

      index_one = File.read File.join('final_app', 'public', 'dogs', 'pugs', 'index.html')
      expect(index_one).to include('<div class="nav-content shallownav" data-props-location="doggies-props.json">I am the default subnav!</div>')

      index_one = File.read File.join('final_app', 'public', 'dogs', 'greyhounds', 'index.html')
      expect(index_one).to include('<div class="nav-content shallownav" data-props-location="doggies-props.json">I am the default subnav!</div>')

      index_two = File.read File.join('final_app', 'public', 'my-docs-repo', 'index.html')
      expect(index_two).to include('<div class="nav-content shallownav" data-props-location="doctastic-props.json">I am the default subnav!</div>')
    end

    it 'properly formats the json props json' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      json_props = File.read File.join('final_app', 'public', 'subnavs', 'doggies-props.json')
      expect(JSON.parse(json_props)['links']).to match_array([
            {'text' => 'First pug', 'title' => true},
            {'url' => '/dogs/pugs/index.html', 'text' => 'First pug'},
            {'text' => 'Second greyhound', 'title' => true},
            {'url' => '/dogs/greyhounds/index.html', 'text' => 'Second greyhound'},
            {'url' => '/dogs/greyhounds/origin.html', 'text' => 'The Origin of the Greyhound'},
            {'url' =>'/dogs/greyhounds/fantabulousness.html', 'text'=> 'Greyhounds are Fantabulous'},
            {'text'=> 'Fun Facts about Greyhounds'},
            {'url'=> '/dogs/greyhounds/colors.html', 'text' => 'Grey?'},
            {'url'=> '/dogs/greyhounds/hounds.html', 'text' => 'Houndy'}
      ])
    end

    context 'when pdf_config specified' do
      let(:subnav) do
        <<YAML
- name: doggies
  pdf_config: dog-pdf.yml
  topics:
  - title: First pug
    toc_path: dogs/pugs/index
  - title: Second greyhound
    toc_path: dogs/greyhounds/index
YAML
      end
      let(:section) do
        <<YAML
- repository:
    name: fantastic/dogs-repo
  directory: dogs
  subnav_name: doggies
YAML
      end

      it 'generates pdf config with each link in the props json' do
        swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
        end

        pdf_config = <<YAML
---
copyright_notice: REPLACE ME
header: REPLACE ME
executable: REPLACE ME
pages:
- dogs/pugs/index.html
- dogs/greyhounds/index.html
- dogs/greyhounds/origin.html
- dogs/greyhounds/fantabulousness.html
- dogs/greyhounds/colors.html
- dogs/greyhounds/hounds.html
YAML

        expect(Pathname(File.join('dog-pdf.yml'))).to exist

        yaml_content = File.read File.join('dog-pdf.yml')
        expect(yaml_content).to eq(pdf_config)
      end
    end

    context 'when multiple config files used' do
      before do
        config = YAML.load(File.read('./config.yml'))
        config.delete('cred_repo')
        config['sections'] = YAML.load(section)
        config['subnavs'] = YAML.load(subnav)
        File.write('./config.yml', config.to_yaml)
        FileUtils.mkdir('./config')
        File.open('./config/sections.yml', 'w') {|f| f.write({'sections' => config['sections']}.to_yaml) }
        File.open('./config/subnavs.yml', 'w') {|f| f.write({'subnavs' => config['subnavs']}.to_yaml) }
      end

      after do
        FileUtils.rmdir('./config')
      end

      it 'should succeed' do
        swallow_stdout do
          `#{gem_root}/install_bin/bookbinder bind local`
        end

        expect(Pathname(File.join('final_app', 'public', 'dogs', 'pugs', 'index.html'))).to exist
      end
    end
  end
end
