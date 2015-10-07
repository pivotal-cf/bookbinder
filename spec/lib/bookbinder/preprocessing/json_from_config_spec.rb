require_relative '../../../../lib/bookbinder/config/subnav_config'
require_relative '../../../../lib/bookbinder/config/topic_config'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/preprocessing/json_from_config'
require_relative '../../../../lib/bookbinder/values/output_locations'
require 'json'

module Bookbinder
  module Preprocessing
    describe JsonFromConfig do
      it 'returns formatted json from topics in a subnav config' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new(
          { 'topics' => [
            {
              'title' => 'Puppy bowls are great',
              'toc_path' => 'puppy-repo/puppy',
              'toc_nav_name' => 'Cat OVERRIDE'
            }
          ]}
        )

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')

        toc_url_md =  <<-EOT
---
title: Title for the Webz Page
---

* [First Document](./first-doc.html)

## Some Menu Subtitle
* [Second Document](../cat-repo/second-doc.html)

## Another Menu with Nested Links

* [Third Document](./third-doc.html)

* [Fourth Document](./fourth-doc.html)
        EOT

        some_json = {links: [
          {text: 'Puppy bowls are great', title: true},
          {url: '/puppy-repo/puppy.html', text: 'Cat OVERRIDE'},
          {url: '/puppy-repo/first-doc.html', text: 'First Document'},
          {text: 'Some Menu Subtitle'},
          {url: '/cat-repo/second-doc.html', text: 'Second Document'},
          {text: 'Another Menu with Nested Links'},
          {url: '/puppy-repo/third-doc.html', text: 'Third Document'},
          {url: '/puppy-repo/fourth-doc.html', text: 'Fourth Document'}
        ]}.to_json

        toc_path = Pathname(output_locations.source_for_site_generator.join('puppy-repo', 'puppy.html.md.erb'))

        allow(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('puppy-repo/puppy'), output_locations.source_for_site_generator) { [toc_path] }

        allow(fs).to receive(:read).with(toc_path) { toc_url_md }

        expect(JsonFromConfig.new(fs).get_links(subnav_config, output_locations.source_for_site_generator)).
          to eq(some_json)
      end

      it 'does not include excluded html attributes' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new(
          { 'subnav_exclusions' => ['.dog'],
            'topics' => [
            {
              'title' => 'Puppy bowls are great',
              'toc_path' => 'puppy-repo/puppy',
            }
          ]}
        )

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')

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

        expect(JsonFromConfig.new(fs).get_links(subnav_config, output_locations.source_for_site_generator)).
          to eq(some_json)
      end
    end
  end
end
