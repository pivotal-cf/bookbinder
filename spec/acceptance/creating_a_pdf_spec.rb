require 'json'
require 'yaml'

require_relative '../helpers/environment_setups'
require_relative '../helpers/use_fixture_repo'
require_relative '../helpers/redirection'

describe 'binding a book locally' do
  include Bookbinder::Redirection

  use_fixture_repo('dita-book')

  around_in_dita_ot_env(ENV)

  let(:pdf_config) do <<-YAML
- repository:
    name: fake-org/dita-section-one
  ditamap_location: example.ditamap
  ditaval_location: dita-filter.ditaval
  output_filename: my-first-pdf
  dependent_sections:
  - repository:
      name: my-org/dita-section-dependency
      directory: dita-section-dependency
- repository:
    name: fake-org/dita-section-two
  ditamap_location: example.ditamap
  ditaval_location: dita-filter.ditaval
  dependent_sections:
  - repository:
      name: my-org/dita-section-dependency
      directory: dita-section-dependency
    YAML
  end

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    config['pdf_sections'] = YAML.load(pdf_config)
    File.write('./config.yml', config.to_yaml)
  end

  let(:gem_root) { File.expand_path('../../../', __FILE__) }

  it 'generates pdfs for each section listed in pdf_config in the artifacts directory' do
    swallow_stdout do
      `#{gem_root}/install_bin/bookbinder imprint local`
    end

    pdf_one = Pathname(File.join('artifacts','pdfs','my-first-pdf.pdf'))
    pdf_two = Pathname(File.join('artifacts','pdfs','example.pdf'))
    expect(pdf_one).to exist
    expect(pdf_two).to exist
  end
end
