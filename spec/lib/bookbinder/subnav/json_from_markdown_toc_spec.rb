require_relative '../../../../lib/bookbinder/config/product_config'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/json_from_markdown_toc'
require_relative '../../../../lib/bookbinder/values/output_locations'
require 'json'

module Bookbinder
  module Subnav
    describe JsonFromMarkdownToc do
      it 'returns formatted json from subnav root in a product config' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::ProductConfig.new({ 'subnav_root' => 'my/index' })

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        my_index =  <<-EOT
---
title: Title for the Webz Page
---

## [First Document](./first-doc.html)

Some Text

## [Second Document](../cat-repo/second-doc.html)

More text

- list item
- another list item

[A link](./third-doc.html)
        EOT

        some_json = {links:
          [
            {
              url: '/my/first-doc.html',
              text: 'First Document'
            },
            {
              url: '/cat-repo/second-doc.html',
              text: 'Second Document'
            }
          ]
        }.to_json

        toc_path = Pathname(output_locations.source_for_site_generator.join('my', 'index.my.extension'))

        allow(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/index'), output_locations.source_for_site_generator) { [toc_path] }

        allow(fs).to receive(:read).with(toc_path) { my_index }

        expect(JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations)).
          to eq(some_json)
      end

      xit 'does not include excluded html attributes' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::ProductConfig.new(
          { 'subnav_exclusions' => ['.dog'],
            'subnav_topics' => [
            {
              'title' => 'Puppy bowls are great',
              'toc_path' => 'puppy-repo/puppy',
            }
          ]}
        )

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        toc_url_md =  <<-EOT

## Some Menu Subtitle
* [A Document](a-doc.html)

<h2 class='dog'>Ignorable</h2
<h2 class='nav-exclude'>Ignorable</h2
<ol class='nav-exclude'>
  <li><a href='ignore-this.html'>Ignorable Document</a></li>
</ol>
        EOT

        some_json = {links: [
          {text: 'Puppy bowls are great', title: true},
          {url: '/puppy-repo/puppy.html', text: 'Puppy bowls are great'},
          {text: 'Some Menu Subtitle'},
          {url: '/puppy-repo/a-doc.html', text: 'A Document'}
        ]}.to_json

        toc_path = Pathname(output_locations.source_for_site_generator.join('puppy-repo', 'puppy.html.md.erb'))

        allow(fs).to receive(:find_files_extension_agnostically).with(Pathname('puppy-repo/puppy'), output_locations.source_for_site_generator) { [toc_path] }

        allow(fs).to receive(:read).with(toc_path) { toc_url_md }

        expect(JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations)).
          to eq(some_json)
      end
    end
  end
end
