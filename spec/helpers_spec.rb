require 'spec_helper'

describe 'middleman helpers' do

  include_context 'tmp_dirs'

  before do
    FileUtils.cp_r File.join('master_middleman/.'), tmpdir
    FileUtils.mkdir_p source_dir
    squelch_middleman_output
  end

  let(:source_dir) { tmp_subdir 'source' }

  describe '#breadcrumbs' do
    let(:source_file_content) { '<%= breadcrumbs %>' }

    context 'when invoked in the top-level index file' do
      let(:source_file_under_test) { 'index.md.erb' }
      let(:source_file_title) { 'Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }

      it 'displays nothing' do
        run_middleman
        expect(output).to be_empty
      end
    end

    context 'when invoked in an index file in a sub-dir, when the parent has a title' do
      let(:source_file_under_test) { File.join('big-dogs', 'index.md.erb') }
      let(:source_file_title) { 'Big Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'big-dogs', 'index.html') }

      before do
        write_markdown_source_file 'index.md.erb', 'Dogs'
      end

      it 'creates a two level breadcrumb' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li').length).to eq(2)
      end

      it 'creates entries for each level of the hierarchy' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li')[0].text).to eq('Dogs')
        expect(doc.css('ul li')[1].text).to eq('Big Dogs')
      end

      it 'gives the last entry an "active" class' do
          run_middleman
          doc = Nokogiri::HTML(output)
          expect(doc.css('ul li')[0]['class']).to be_nil
          expect(doc.css('ul li')[1]['class']).to eq('active')
      end
    end

    context 'when invoked in an index file in a sub-dir, when the parent is not markdown' do
      let(:source_file_under_test) { File.join('big-dogs', 'index.md.erb') }
      let(:source_file_title) { 'Big Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'big-dogs', 'index.html') }

      before do
        full_path = File.join(source_dir, 'index.md.erb')
        File.open(full_path, 'w') {|f| f.write('<html><head><title>Dogs</title></head><body>Dogs are great!</body></html>')}
      end

      it 'creates a one level breadcrumb' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li').length).to eq(1)
      end

      it 'creates an entry for the bottom level' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li')[0].text).to eq('Big Dogs')
      end
    end
  end

  def write_markdown_source_file(path_under_source_dir, title, content = nil)
    full_path = File.join(source_dir, path_under_source_dir)
    full_pathname = Pathname.new(full_path)
    FileUtils.mkdir_p full_pathname.dirname
    final_content = "---\ntitle: #{title}\n---\n#{content}"
    File.open(full_path, 'w') {|f| f.write(final_content)}
  end

  def run_middleman
    write_markdown_source_file source_file_under_test, source_file_title, source_file_content
    MiddlemanRunner.new.run tmpdir
  end

end