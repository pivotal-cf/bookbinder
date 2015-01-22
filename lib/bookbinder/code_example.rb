module Bookbinder
  CodeExample = Struct.new(:path_to_repository,
                           :full_name,
                           :copied,
                           :destination_dir,
                           :directory_name)
end
