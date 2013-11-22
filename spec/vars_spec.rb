require 'spec_helper'

describe 'middleman helpers' do

  include_context 'tmp_dirs'

  before do
    FileUtils.cp_r File.join('master_middleman/.'), tmpdir
    FileUtils.mkdir_p source_dir
    squelch_middleman_output
  end

  let(:source_dir) { tmp_subdir 'source' }

  describe '#vars' do
    let(:source_file_content) { "<%= vars['var_name'] %>" }

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

  # TODO: DRY up this and breadcrumbs spec
  def write_markdown_source_file(path_under_source_dir, title, content = nil)
    full_path = File.join(source_dir, path_under_source_dir)
    full_pathname = Pathname.new(full_path)
    FileUtils.mkdir_p full_pathname.dirname
    final_content = "---\ntitle: #{title}\n---\n#{content}"
    File.open(full_path, 'w') {|f| f.write(final_content)}
  end

  def run_middleman(template_variables)
    write_markdown_source_file source_file_under_test, source_file_title, source_file_content
    MiddlemanRunner.new.run tmpdir, template_variables
  end

end