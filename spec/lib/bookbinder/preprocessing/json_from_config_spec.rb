require_relative '../../../../lib/bookbinder/config/subnav_config'
require_relative '../../../../lib/bookbinder/config/topic_config'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/preprocessing/json_from_config'
require_relative '../../../../lib/bookbinder/values/output_locations'
require 'json'

module Bookbinder
  module Preprocessing
    describe JsonFromConfig do
      it 'returns formatted json from topics in a subnav config, ignoring elements marked for exclusion' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new(
          {'topics' => [
            {
              'title' => 'Puppy bowls are great',
              'toc_file' => 'puppy-repo/puppy',
              'toc_nav_name' => 'Cat OVERRIDE'
            }
          ]}
        )

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')

        toc_url_md =  <<-EOT
---
title: Title for the Webz Page
---

<h2 class='nav-exclude'>TOC</h2>
* [First Document](first-doc.html)

## Some Menu Subtitle
* [Second Document](second-doc.html)
* [Third Document](third-doc.html)

## Another Menu with Nested Links

* [Fourth Document](fourth-doc.html)

* [Fifth Document](fifth-doc.html)

* [Sixth Document](sixth-doc.html)

<h2 class='nav-exclude'>Ignorable</h2
<ol class='nav-exclude'>
  <li><a href='ignore-this.html'>Ignorable Document</a></li>
</ol>
<h2 class='nav-exclude'>Nonsensical</h2>
<ul class='nav-exclude'>
  <li><a href='do-not-read.html'>Nonsense Document</a></li>
</ul>
        EOT

        some_json = {links: [
          {text: 'Puppy bowls are great', title: true},
          {url: '/puppy-repo/puppy.html', text: 'Cat OVERRIDE'},
          {url: 'first-doc.html', text: 'First Document'},
          {text: 'Some Menu Subtitle'},
          {url: 'second-doc.html', text: 'Second Document'},
          {url: 'third-doc.html', text: 'Third Document'},
          {text: 'Another Menu with Nested Links'},
          {url: 'fourth-doc.html', text: 'Fourth Document'},
          {url: 'fifth-doc.html', text: 'Fifth Document'},
          {url: 'sixth-doc.html', text: 'Sixth Document'}
        ]}.to_json

        toc_path = Pathname(output_locations.source_for_site_generator.join('puppy-repo', 'puppy.html.md.erb'))

        allow(fs).to receive(:find_files_extension_agnostically).with(output_locations.source_for_site_generator.join('puppy-repo'), 'puppy-repo/puppy') { [toc_path] }

        allow(fs).to receive(:read).with(toc_path) { toc_url_md }

        expect(JsonFromConfig.new(fs).get_links(subnav_config, output_locations.source_for_site_generator)).
          to eq(some_json)
      end
    end
  end
end
