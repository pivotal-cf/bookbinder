class CssLinkChecker
  def broken_links_in_all_stylesheets
    localized_links_in_stylesheets.reject { |link| target_exists?(link) }
  end

  private

  def localized_links_in_stylesheets
    links_in_stylesheets = []

    Dir.glob('**/*.css').each { |stylesheet| links_in_stylesheets.concat localized_links_from(stylesheet) }

    links_in_stylesheets
  end

  def localized_links_from(stylesheet)
    localized_uris = []
    css = CssParser::Parser.new
    css.load_uri! stylesheet

    css.each_selector do |s, declaration, sp|
      contents_of_url_value = /url\((.*?)\)/
      file_url = declaration.match contents_of_url_value
      localized_uris << Spider.prepend_location(stylesheet, file_url[1]) if file_url
    end

    localized_uris
  end

  def target_exists?(localized_identifier)
    link = strip_location(localized_identifier)

    data_uri      = /^['"]?data:image\//
    remote_uri    = /^['"]?https?:\/\//
    absolute_uri  = /^['"]?\//
    relative_uri  = //

    case link
      when data_uri then true
      when remote_uri then http_reachable?(link)
      when absolute_uri then File.exists?(File.join('.', 'public', link))
      when relative_uri then File.exists?(File.expand_path(File.join 'public', 'stylesheets', link))
    end
  end

  def strip_location(id)
    id.split('=> ').last
  end

  def http_reachable?(link)
    Net::HTTP.get_response(URI(link)).code == '200'
  rescue SocketError => e
    return false
  end
end