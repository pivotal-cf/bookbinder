require 'pathname'

class FakeFilesystemAccessor
  NotFaked = Class.new(Exception)
  NotFound = Class.new(Exception)

  def initialize(files = {})
    @files = { full_path: '', children: process(files) }
  end

  def file_exist?(path)
    entry_from_path(path)
    true
  rescue NotFound
    false
  end

  def is_file?(path)
    entry = entry_from_path(path)
    entry.has_key?(:contents)
  rescue NotFound
    false
  end

  def is_dir?(path)
    entry = entry_from_path(path)
    entry.has_key?(:children)
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
    dirs = path_parts(path)

    make_dir_if_not_exist(dirs)
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
    make_directory(File.dirname(dest))

    source_dir = entry_from_path(src)
    dest_dir = entry_from_path(File.dirname(dest))

    dest_name = File.basename(dest)

    raise "Destination #{dest} already exists" if dest_dir[:children].has_key?(dest_name)
    dest_dir[:children][dest_name] = source_dir
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

  def path_parts(path)
    raise "#{path} is not an absolute path" unless path.to_s[0] == '/'

    path_split = path.to_s.split('/')
    path_split[1..-1] || []
  end

  def entry_from_path(path)
    path_split = path_parts(path)
    fs_root = @files

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

  def make_dir_if_not_exist(dirs, parent=@files)
    return unless dirs.size > 0

    this_one = parent[:children][dirs[0]]
    full_path = File.join(parent[:full_path], dirs[0])

    unless this_one
      this_one = parent[:children][dirs[0]] = {
        type: :folder,
        full_path: full_path,
        children: {}
      }
    end

    make_dir_if_not_exist(dirs[1..-1], this_one)
  end
end
