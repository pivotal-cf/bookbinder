class Sieve
  def initialize(domain: nil)
    @unverified_fragments_by_url = {}
    @domain = domain
  end

  def links_into(page, broken_links, sitemap, is_first_pass)
    if page.not_found?
      broken_links << page.url.to_s if is_first_pass
    else
      sitemap << page.url.to_s
      broken_links.concat broken_fragments_targeting page, is_first_pass
      @unverified_fragments_by_url.merge! fragments_targeting_other_pages_from page
    end
  end

  private

  def broken_fragments_targeting(page, first_pass)
    first_pass ? local_fragments_missing_from(page) : remote_fragments_missing_from(page)
  end

  def local_fragments_missing_from(page)
    page.fragment_identifiers(targeting_locally: true).reject { |id| page.has_target_for?(id) }
  end

  def fragments_targeting_other_pages_from(page)
    some_array = page.fragment_identifiers(targeting_locally: false).map {|href| href.split('#') }

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
    @unverified_fragments_by_url.fetch(url, []).reject { |id| page.has_target_for?(id) }
  end
end
