module Bookbinder
  OutputLocations = Struct.new(
      :source_for_site_generator,
      :dita_home_dir,
      :cloned_dita_dir,
      :html_from_dita_dir,
      :formatted_dir,
      :subnavs_for_layout_dir,
      :dita_subnav_template_path
  )
end