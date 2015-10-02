require_relative '../../../../lib/bookbinder/preprocessing/json_from_config'
require_relative '../../../../lib/bookbinder/config/subnav_config'
require 'json'

module Bookbinder
  module Preprocessing
    describe JsonFromConfig do
      it 'returns formatted json from topics in a subnav config, ignoring elements marked for exclusion' do
        subnav_config = Config::SubnavConfig.new(
          {'topics' => [
            {
              'title' => 'Puppy bowls are great',
              'toc_url' => 'puppy bowl dot com'
            }
          ]}
        )

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')

        toc_url_html = <<-EOT
<main>
  <div>
    <h2 class='nav-exclude'>TOC</h2>
    <ul>
      <li><a href='first-doc.html'>First Document</a></li>
    </ul>
    <h2>Some Menu Subtitle</h2>
    <ul>
      <li><a href='second-doc.html'>Second Document</a></li>
      <li><a href='third-doc.html'>Third Document</a></li>
    </ul>
    <h2 class='nav-exclude'>Ignorable</h2
    <ol class='nav-exclude'>
      <li><a href='ignore-this.html'>Ignorable Document</a></li>
    </ol>
  </div>
  <h2 class='nav-exclude'>Nonsensical</h2>
  <ul class='nav-exclude'>
    <li><a href='do-not-read.html'>Nonsense Document</a></li>
  </ul>
</main>
        EOT

        some_json = {links: [
          {text: 'Puppy bowls are great', title: true},
          {url: 'first-doc.html', text: 'First Document'},
          {text: 'Some Menu Subtitle'},
          {url: 'second-doc.html', text: 'Second Document'},
          {url: 'third-doc.html', text: 'Third Document'}
        ]}.to_json

        allow(fs).to receive(:file_exist?).with('source/puppy bowl dot com.md.erb') { true }
        allow(fs).to receive(:read).with('source/puppy bowl dot com.md.erb') { toc_url_html }

        expect(JsonFromConfig.new(fs).get_links(subnav_config, Pathname('source'))).to eq(some_json)
      end
    end
  end
end
