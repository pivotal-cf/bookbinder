require 'spec_helper'

describe 'generating a book' do
  include_context 'tmp_dirs'

  around_with_fixture_repo &:run

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  context 'when no pdf index file is specified' do
    it 'generates a pdf based on the filename option' do
      silence_io_streams do
        `#{GEM_ROOT}/bin/bookbinder publish local`
        `#{GEM_ROOT}/bin/bookbinder generate_pdf`
      end
      expect(File.exists?(File.join('final_app', 'public', 'GeneratedPdf.pdf'))).to eq(true)
    end
  end

  context 'when a pdf index file is specified' do

    before do
      File.write("#{filename}.yml", %w(index.html dogs/index.html foods/savory/index.html foods/sweet/index.html).to_yaml)
    end

    let(:filename) { 'PDFsAreCool' }

    it 'generates a pdf with the same name as the index file' do
      silence_io_streams do
        `#{GEM_ROOT}/bin/bookbinder publish local`
        `#{GEM_ROOT}/bin/bookbinder generate_pdf #{filename}.yml`
      end
      expect(File.exists?(File.join('final_app', "#{filename}.pdf"))).to eq(true)
    end
  end
end
