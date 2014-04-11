module SpecHelperMethods
  def squelch_middleman_output
    Thor::Shell::Basic.any_instance.stub(:say_status) {}
    Middleman::Logger.any_instance.stub(:add) {}
  end

  def write_markdown_source_file(path_under_source_dir, title, content = nil, breadcrumb_title = nil)
    full_path = File.join(source_dir, path_under_source_dir)
    full_pathname = Pathname.new(full_path)
    FileUtils.mkdir_p full_pathname.dirname
    breadcrumb_code = breadcrumb_title ? "breadcrumb: #{breadcrumb_title}\n" : ''
    final_content = "---\ntitle: #{title}\n#{breadcrumb_code}---\n#{content}"
    File.open(full_path, 'w') { |f| f.write(final_content) }
    end

  def generate_middleman_with(index_page)
    dir = tmp_subdir 'master_middleman'
    source_dir = File.join(dir, 'source')
    FileUtils.mkdir source_dir
    FileUtils.cp File.join('spec', 'fixtures', index_page), File.join(source_dir, 'index.html.md.erb')
    dir
  end
end