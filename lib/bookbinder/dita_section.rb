module Bookbinder
  DitaSection = Struct.new(:path_to_local_repo,
                           :ditamap_location,
                           :full_name,
                           :target_ref,
                           :directory)
end