class Sieve
  def initialize(domain: ->(){ raise 'You must supply a domain parameter.' }.call)
    @unverified_fragments_by_url = {}
    @domain = domain
  end

  def links_from(page, is_first_pass)
    broken_links = []
    workin_links = []

    if page.not_found? && is_first_pass
      broken_links << Spider.prepend_location(page.referer, page.url)
    else
      workin_links << page.url.to_s
      broken_links.concat broken_fragments_targeting(page, is_first_pass)
      @unverified_fragments_by_url.merge! fragments_targeting_other_pages_from page
    end

    return broken_links, workin_links
  end

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

    data_uri      = /^data:image\//
    remote_uri    = /^https?:\/\//
    absolute_uri  = /^\//
    relative_uri  = //

    case link
      when data_uri then true
      when remote_uri then http_reachable?(link)
      when absolute_uri then File.exists?(File.join('.', 'public', link))
      when relative_uri then File.exists?(File.expand_path(File.join 'public', 'stylesheets', link))
    end
  end

  def http_reachable?(link)
    Net::HTTP.get_response(URI(link)).code == '200'
  end

  def broken_fragments_targeting(page, first_pass)
    first_pass ? local_fragments_missing_from(page) : remote_fragments_missing_from(page)
  end

  def local_fragments_missing_from(page)
    local_fragments = page.fragment_identifiers targeting_locally: true
    local_fragments.map { |uri| Spider.prepend_location(page.url, uri) unless page.has_target_for?(uri) }.compact
  end

  def fragments_targeting_other_pages_from(page)
    uris_with_fragments = page.fragment_identifiers(targeting_locally: false)
    uris_with_fragments.reduce({}) { |dict, uri| merge_uris_under_targets(dict, page, uri) }
  end

  def merge_uris_under_targets(dict, page, uri)
    target_url = URI::join @domain, uri.path
    localized_identifier = Spider.prepend_location(page.url, "##{uri.fragment}")

    if dict.has_key? target_url
      dict[target_url] << localized_identifier
    else
      dict[target_url] = [localized_identifier]
    end

    dict
  end

  def remote_fragments_missing_from(page)
    @unverified_fragments_by_url.fetch(page.url, []).reject { |localized_identifier| page.has_target_for? URI(strip_location(localized_identifier)) }
  end

  def strip_location(id)
    id.split('=> ').last
  end
end
