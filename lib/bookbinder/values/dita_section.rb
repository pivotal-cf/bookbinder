module Bookbinder
  DitaSection = Struct.new(:path_to_local_repo,
                           :ditamap_location,
                           :ditaval_location,
                           :full_name,
                           :target_ref,
                           :directory,
                           :output_locations) do
                             def subnav
                               namespace = directory.gsub('/', '_')
                               template = "dita_subnav"
                               {namespace => template}
                             end

                             def html_from_dita_section_dir
                               File.join(output_locations.html_from_dita_dir, directory)
                             end

                             def formatted_section_dir
                               File.join(output_locations.formatted_dir, directory)
                             end

                             def section_source_for_site_generator
                               File.join(output_locations.source_for_site_generator, directory)
                             end

                             def absolute_path_to_ditamap
                               ditamap_location ? File.join(path_to_local_repo, ditamap_location) : nil
                             end

                             def absolute_path_to_ditaval
                               ditaval_location ? File.join(path_to_local_repo, ditaval_location) : nil
                             end
                           end
end
