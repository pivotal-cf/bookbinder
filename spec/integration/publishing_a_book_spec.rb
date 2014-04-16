require 'spec_helper'

describe 'publishing a book' do
  include_context 'tmp_dirs'

  around_with_fixture_repo do |spec|
    spec.run
  end

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  it 'provides the production host to the ERB templates' do
    silence_io_streams do
      `#{GEM_ROOT}/bin/bookbinder publish local`
    end

    index = File.read File.join('final_app', 'public', 'index.html')
    expect(index).to include('My production host is: docs.example.com')
  end

  it 'generates a pdf based on the filename option' do
    silence_io_streams do
      `#{GEM_ROOT}/bin/bookbinder publish local`
    end
    expect(File.exists?(File.join('final_app', 'public', 'TestPdf.pdf'))).to eq(true)
  end
end