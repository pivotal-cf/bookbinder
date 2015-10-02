require_relative '../../../../lib/bookbinder/preprocessing/json_from_toc_url'

module Bookbinder
  module Preprocessing
    describe JsonFromTocUrl do
      it 'produces json given a url to parse' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        json_generator = JsonFromTocUrl.new(fs)
        toc_url_html = <<-EOT
<main>
  <div>
    <h2>TOC</h2>
    <ul>
      <li><a href='first-doc.html'>First Document</a></li>
    </ul>
    <h2>Another TOC</h2>
    <ul>
      <li><a href='second-doc.html'>Second Document</a></li>
      <li><a href='third-doc.html'>Third Document</a></li>
    </ul>
  </div>
</main>
EOT

        parsed_json = {
          links: [
            {text: 'TOC'},
            {url: 'first-doc.html', text: 'First Document'},
            {text: 'Another TOC'},
            {url: 'second-doc.html', text: 'Second Document'},
            {url: 'third-doc.html', text: 'Third Document'}
          ]
        }.to_json

        allow(fs).to receive(:read).with('toc url') {toc_url_html}

        expect(json_generator.parse('toc url')).to eq(parsed_json)
      end
    end
  end
end
