class Sieve
  def initialize(domain: nil)
    @unverified_fragments_by_url = {}
    @domain = domain
  end

  def links_into(page, broken_links, sitemap, first_pass)
    if page.not_found?
      broken_links << page.url.to_s if first_pass
    else
      sitemap << page.url.to_s
      if page.doc
        if first_pass
          broken_links.concat local_fragments_missing_from page
        else
          broken_links.concat remote_fragments_missing_from page
        end
        @unverified_fragments_by_url.merge! fragments_targeting_other_pages_from page
      end
    end
  end

  private

  def local_fragments_missing_from(page)
    fragment_identifiers_on(page, targeting_locally: true).select { |id| no_target_for id, on: page }
  end

  def fragment_identifiers_on(page, targeting_locally: false)
    fragment_regex = targeting_locally ? /^#.*/ : /.+#.*/
    anchor_tags = page.doc.css('a')
    anchor_tags.reduce([]) do |identifiers, anchor|
      id = fragment_id(anchor, fragment_regex)
      identifiers << id if id
      identifiers
    end
  end

  def fragment_id(anchor, regexp)
    if anchor['href']
      possible_tag = anchor['href'].match(regexp).to_s
      possible_tag unless possible_tag.empty?
    end
  end

  def no_target_for(anchor, on: nil)
    id_selector = anchor
    name_selector = "[name=#{anchor.to_s.gsub('#', '')}]"
    on.doc.css(id_selector).none? && on.doc.css(name_selector).none?
  rescue Nokogiri::CSS::SyntaxError
    true
  end

  def fragments_targeting_other_pages_from(page)
    some_array = fragment_identifiers_on(page, targeting_locally: false).map {|href| href.split('#') }

    some_array.reduce({}) do |dict, pair|
      target_url = "#@domain/#{pair[0]}"
      identifier = "##{pair[1]}"

      if dict.has_key? target_url
        dict[target_url] << identifier
      else
        dict[target_url] = [identifier]
      end

      dict
    end
  end

  def remote_fragments_missing_from(page)
    url = page.url.to_s
    @unverified_fragments_by_url.fetch(url, []).select { |id| no_target_for id, on: page }
  end
end
