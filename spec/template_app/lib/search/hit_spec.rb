require_relative '../../../../template_app/lib/search/hit'

module Bookbinder::Search
  describe Hit do
    it 'trims the site information out of the title' do
      hit = Hit.new('_source' => { 'title' => 'Foo Bar | More Stuff', 'url' => 'foo.html' }, 'highlight' => { 'text' => ['foo'] })
      expect(hit.title).to eq('Foo Bar')
    end

    it 'allows | character in the page title before site information' do
      hit = Hit.new('_source' => { 'title' => 'Foo | Bar | More Stuff', 'url' => 'foo.html' }, 'highlight' => { 'text' => ['foo'] })
      expect(hit.title).to eq('Foo | Bar')
    end
  end
end
