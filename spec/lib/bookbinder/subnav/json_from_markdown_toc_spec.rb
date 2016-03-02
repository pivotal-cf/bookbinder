require_relative '../../../../lib/bookbinder/config/product_config'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/json_from_markdown_toc'
require_relative '../../../../lib/bookbinder/values/output_locations'
require 'json'

module Bookbinder
  module Subnav
    describe JsonFromMarkdownToc do
      it 'returns formatted json from subnav root in a product config' do
        output_locations = OutputLocations.new(context_dir: '/')
        subnav_config = Config::ProductConfig.new({ 'subnav_root' => 'my/index' })

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        root_index =  <<-EOT
---
title: Title for the Webz Page
---

## <a href="./cats/first-doc.html" class="subnav">First Document</a>

Some Text

## <a href="./second-doc.html" class="subnav">Second Document</a>

More text

- list item
- another list item

## <a href="./unlinked.html">My Unlinked Header</a>

## <a id='my-id'></a> My Quicklink

[A link](./third-doc.html)
        EOT

        first_doc = <<-EOT
## <a href="../nested-doc.html" class="subnav">Nested Link</a>

Some Text
        EOT

        second_doc = <<-EOT
Just some text here.
        EOT

        nested_doc = <<-EOT
Move along, nothing to see.
        EOT

        json_toc = {links:
          [
            {
              url: '/my/cats/first-doc.html',
              text: 'First Document',
              nestedLinks: [
                {
                  url: '/my/nested-doc.html',
                  text: 'Nested Link'
                }
              ]
            },
            {
              url: '/my/second-doc.html',
              text: 'Second Document'
            }
          ]
        }.to_json

        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/index'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/index.html')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/cats/first-doc.html'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/cats/first-doc.html.md')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/second-doc.html'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/second-doc.html.md.erb')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/nested-doc.html'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/nested-doc.html')] }

        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/index.html')) { root_index }
        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/cats/first-doc.html.md')) { first_doc }
        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/second-doc.html.md.erb')) { second_doc }
        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/nested-doc.html')) { nested_doc }

        expect(JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations)).
          to eq(json_toc)
      end

      it 'raises an error if a link is included twice in a subnav' do
        output_locations = OutputLocations.new(context_dir: '/')
        subnav_config = Config::ProductConfig.new({ 'subnav_root' => 'my/index' })

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        root_index =  <<-EOT
---
title: Title for the Webz Page
---

## <a href="./first-doc.html" class="subnav">First Document</a>

Some Text
        EOT

        first_doc = <<-EOT
## <a href="./index.html" class="subnav">Nested Link</a>

Some Text
        EOT

        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/index'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/index.html')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/index.html'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/index.html')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/first-doc.html'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/first-doc.extension')] }

        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/index.html')) { root_index }
        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/first-doc.extension')) { first_doc }

        expect { JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations) }.
          to raise_error(JsonFromMarkdownToc::SubnavDuplicateLinkError) do |error|
            expect(error.message).to include('my/index.html')
        end
      end

      it 'raises an error if a link goes to a bogus place' do
        output_locations = OutputLocations.new(context_dir: '/')
        subnav_config = Config::ProductConfig.new({ 'subnav_root' => 'my/index' })

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        root_index =  <<-EOT
---
title: Title for the Webz Page
---

## <a href="./bogus-doc.html" class="subnav">Bogus Document</a>

Some Text
        EOT

        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/index'), output_locations.source_for_site_generator) { [Pathname('/output/master_middleman/source/my/index.html')] }
        expect(fs).to receive(:find_files_extension_agnostically).
            with(Pathname('my/bogus-doc.html'), output_locations.source_for_site_generator) { [] }

        allow(fs).to receive(:read).with(Pathname('/output/master_middleman/source/my/index.html')) { root_index }

        expect { JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations) }.
          to raise_error(JsonFromMarkdownToc::SubnavBrokenLinkError) do |error|
          expect(error.message).to include('my/bogus-doc.html')
        end
      end

      it 'barfs informatively if it cannot find a subnav root' do

        output_locations = OutputLocations.new(context_dir: '/')
        subnav_config = Config::ProductConfig.new({ 'subnav_root' => 'my/index' })

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)

        expect(fs).to receive(:find_files_extension_agnostically).with(Pathname('my/index'), output_locations.source_for_site_generator){[]}

        expect { JsonFromMarkdownToc.new(fs).get_links(subnav_config, output_locations) }.to raise_error(JsonFromMarkdownToc::SubnavRootMissingError)





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
