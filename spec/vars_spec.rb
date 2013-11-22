require 'spec_helper'

describe '#vars' do

  include_context 'tmp_dirs'

  before do
    FileUtils.cp_r File.join('master_middleman/.'), tmpdir
    FileUtils.mkdir_p source_dir
    squelch_middleman_output
  end

  let(:source_dir) { tmp_subdir 'source' }
  let(:source_file_content) { '<%= vars.var_name %>' }

  context 'when the variable is defined' do
    let(:source_file_under_test) { 'index.md.erb' }
    let(:source_file_title) { 'Dogs' }
    let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }

    it 'displays nothing' do
      run_middleman 'var_name' => 'A Variable Value'
      expect(output).to include('A Variable Value')
    end
  end

end
