require 'pathname'

class FakeFilesystemAccessor
  NotFaked = Class.new(Exception)
  NotFound = Class.new(Exception)

  def initialize(files = {})
    @files = { children: process(files) }
  end

  def file_exist?(path)
    entry_from_path(path)
    true
  rescue NotFound
    false
  end

  def write(to: nil, text: nil)
    raise NotFaked
  end

  def overwrite(to: nil, text: nil)
    raise NotFaked
  end

  def read(path)
    entry_from_path(path).fetch(:contents)
  end

  def empty_directory(path)
    raise NotFaked
  end

  def remove_directory(path)
    raise NotFaked
  end

  def make_directory(path)
    raise NotFaked
  end

  def copy(src, dest)
    raise NotFaked
  end

  def copy_and_rename(src, dest)
    raise NotFaked
  end

  def copy_contents(src, dest)
    raise NotFaked
  end

  def copy_including_intermediate_dirs(file, root, dest)
    raise NotFaked
  end

  def link_creating_intermediate_dirs(src, dest)
    raise NotFaked
  end

  def rename_file(path, new_name)
    raise NotFaked
  end

  def find_files_with_ext(ext, path)
    extension = %r{\.#{ext}\z}
    find_files_recursively(path).select { |file_path| extension.match(file_path) }
  end

  def relative_path_from(src, target)
    raise NotFaked
  end

  def find_files_recursively(from)
    dir = entry_from_path(from)
    recursive_files_in(dir[:children])
  end

  def find_files_extension_agnostically(pattern, directory='.')
    raise NotFaked
  end

  def source_file_exists?(directory, path_to_file)
    raise NotFaked
  end

  private

  def recursive_files_in(dir)
    dir.each.with_object([]) do |(entry, details), list|
      if details[:type] == :file
        list << details[:full_path]
      else
        list.concat(recursive_files_in(details[:children]))
      end
    end
  end

  def entry_from_path(path)
    path_split = path.to_s.split('/')
    fs_root = if path_split[0] == ''
                path_split = path_split[1..-1]
                @files
              else
                raise "#{path} is not an absolute path"
              end

    path_split.inject(fs_root) do |parent, dir_name|
      parent[:children].fetch(dir_name) { raise NotFound, dir_name }
    end
  end

  def process(file_list, parent_path='')
    file_list.inject({}) do |kids, (name, contents)|
      full_path = File.join(parent_path, name)
      entry = case contents
              when Hash
                {
                  type: :folder,
                  full_path: full_path,
                  children: process(contents, full_path)
                }
              when String
                {
                  type: :file,
                  full_path: full_path,
                  contents: contents
                }
              end

      kids.merge(name => entry)
    end
  end
end
