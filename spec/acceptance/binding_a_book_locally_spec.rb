require 'json'
require 'yaml'
require 'nokogiri'

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
      `#{gem_root}/install_bin/bookbinder bind local --verbose`
    end

    index = File.read File.join('final_app', 'public', 'index.html')
    expect(index).to include('My production host is: docs.example.com')
  end

  context 'when section directory specified in config.yml' do
    let(:section) do <<-YAML
- repository:
    name: fantastic/dogs-repo
    at_path: big_dogs/great_danes
  directory: tiny_guys
    YAML
    end

    before do
      config = YAML.load(File.read('./config.yml'))
      config['sections'] = YAML.load(section)
      File.write('./config.yml', config.to_yaml)
    end

    it 'puts specified content into named directory' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      expect(Pathname(File.join('final_app', 'public', 'tiny_guys', 'great_danes.html'))).to exist
    end
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
      expect(index).to include('<p><img src="images/breeds.png" alt="Breeds" /></p>')
    end
  end

  context 'when products with subnav root are specified in config.yml' do
    let(:section) do
<<YAML
- repository:
    name: fantastic/dogs-repo
    ref: 'dog-sha'
  directory: dogs
  product_id: doggies
- repository:
    name: fantastic/my-docs-repo
  product_id: doctastic
YAML
    end

    let(:product) do
<<YAML
- id: doggies
  subnav_root: dogs/index
- id: doctastic
  subnav_root: my-docs-repo/index
YAML
    end

    before do
      config = YAML.load(File.read('./config.yml'))
      config.delete('cred_repo')
      config['sections'] = YAML.load(section)
      config['products'] = YAML.load(product)
      File.write('./config.yml', config.to_yaml)
    end

    it 'generates nav html' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local`
      end

      pugs_index = File.read File.join('final_app', 'public', 'dogs', 'pugs', 'index.html')
      pugs_doc = Nokogiri::HTML(pugs_index)
      expect(pugs_doc.css('.nav-content ul li').size).to eq(2)
      expect(pugs_doc.css('.nav-content ul li:nth-child(1)').text.strip).to eq('First pug')
      expect(pugs_doc.css('.nav-content ul li:nth-child(1) a').first['href']).to eq('/dogs/pugs/index.html')
      expect(pugs_doc.css('.nav-content ul li:nth-child(2)').text.strip).to eq('Second greyhound')
      expect(pugs_doc.css('.nav-content ul li:nth-child(2) a').first['href']).to eq('/dogs/greyhounds/index.html')

      greyhounds_index = File.read File.join('final_app', 'public', 'dogs', 'greyhounds', 'index.html')
      greyhounds_doc = Nokogiri::HTML(greyhounds_index)
      expect(greyhounds_doc.css('.nav-content ul li').size).to eq(2)
      expect(greyhounds_doc.css('.nav-content ul li:nth-child(1)').text.strip).to eq('First pug')
      expect(greyhounds_doc.css('.nav-content ul li:nth-child(2)').text.strip).to eq('Second greyhound')

      docs_repo_index = File.read File.join('final_app', 'public', 'my-docs-repo', 'index.html')
      docs_repo_doc = Nokogiri::HTML(docs_repo_index)
      expect(docs_repo_doc.css('.nav-content ul li').size).to eq(0)
    end

    context 'when pdf_config specified' do
      let(:product) do
        <<YAML
- id: doggies
  pdf_config: dog-pdf.yml
  subnav_root: dogs/index
YAML
      end
      let(:section) do
        <<YAML
- repository:
    name: fantastic/dogs-repo
  directory: dogs
  product_id: doggies
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
        config['products'] = YAML.load(product)
        File.write('./config.yml', config.to_yaml)
        FileUtils.mkdir('./config')
        File.open('./config/sections.yml', 'w') {|f| f.write({'sections' => config['sections']}.to_yaml) }
        File.open('./config/products.yml', 'w') {|f| f.write({'products' => config['products']}.to_yaml) }
      end

      after do
        FileUtils.rm_rf('./config')
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
