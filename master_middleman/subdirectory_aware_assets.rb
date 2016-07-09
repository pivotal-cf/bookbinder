class SubdirectoryAwareAssets < ::Middleman::Extension
  helpers do
    def asset_path(path, prefix="", options={})
      url = super(path, prefix, options)

      unless global_asset_at? url
        current_dir = Pathname('/' + current_resource.destination_path)
        url = Pathname(url).relative_path_from(current_dir.dirname).to_s
      end

      # middleman assumes your assets live at the top level, but they may be in the nested repos instead
      # here we start at top level and dive down until we find the real asset
      current_page_path_parts = current_resource.destination_path.split('/')
      current_page_path_parts.pop
      current_page_dir = File.join('source', current_page_path_parts, '')
      while (!File.exists? "#{current_page_dir}#{url}") && url.match(/^\.\.\//) do
        url = url.gsub(/^\.\.\//, "")
      end

      url
    end

    private

    def global_asset_at?(path)
      path.include?('//') ||
        path.start_with?('data:') ||
        !current_resource ||
        path.index('.css') ||
        path.index('.js')
    end
  end

end

::Middleman::Extensions.register(:subdirectory_aware_assets, SubdirectoryAwareAssets)
