require 'spec_helper'

describe 'calling bookbinder with pdf configuration' do
  include_context 'tmp_dirs'

  around_with_fixture_repo do |spec|
    spec.run
  end

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  it 'generates a pdf based on the filename option' do
    `#{GEM_ROOT}/bin/bookbinder publish local`
    expect(File.exists?(File.join('final_app', 'public', 'TestPdf.pdf'))).to eq(true)
  end
end
