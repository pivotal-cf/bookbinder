module Bookbinder
  module SpecHelperMethods
    def expect_to_receive_and_return_real_now(subject, method, *args)
      real_obj = subject.public_send(method, *args)
      expect(subject).to receive(method).with(*args).and_return(real_obj)
      real_obj
    end

    def generate_middleman_with(index_page)
      dir = tmp_subdir 'master_middleman'
      source_dir = File.join(dir, 'source')
      FileUtils.mkdir source_dir
      FileUtils.cp File.join('spec', 'fixtures', index_page), File.join(source_dir, 'index.html.md.erb')
      dir
    end

    def squelch_middleman_output
      allow_any_instance_of(Thor::Shell::Basic).to receive(:say_status) {}
      allow_any_instance_of(Middleman::Logger).to receive(:add) {}
    end

    def write_markdown_source_file(path_under_source_dir, title, content = nil, breadcrumb_title = nil, subnav = nil)
      full_path = File.join(source_dir, path_under_source_dir)
      full_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p full_pathname.dirname
      breadcrumb_code = breadcrumb_title ? "breadcrumb: #{breadcrumb_title}\n" : ''
      subnav_code = subnav ? "index_subnav: #{subnav}" : ''
      final_content = "---\ntitle: #{title}\n#{breadcrumb_code}\n#{subnav_code}\n---\n#{content}"
      File.open(full_path, 'w') { |f| f.write(final_content) }
    end

    def write_subnav_content(path_under_source_dir, subnav_content = nil)
      full_path = File.join(source_dir, path_under_source_dir)
      full_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p full_pathname.dirname
      subnav_code = subnav_content ? subnav_content : ''
      File.open(full_path, 'w') { |f| f.write(subnav_code) }
    end

    def silence_io_streams
      begin
        orig_stderr = $stderr.clone
        orig_stdout = $stdout.clone
        $stderr.reopen File.new('/dev/null', 'w')
        $stdout.reopen File.new('/dev/null', 'w')
        retval = yield
      rescue Exception => e
        $stdout.reopen orig_stdout
        $stderr.reopen orig_stderr
        raise e
      ensure
        $stdout.reopen orig_stdout
        $stderr.reopen orig_stderr
      end
      retval
    end
  end
end