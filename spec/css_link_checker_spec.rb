require 'spec_helper'

describe CssLinkChecker do
  let(:non_responsive_uri) { "http://www.gopivotal.com/sites/all/themes/gopo13/images/pivotal-logo.png" }
  let(:test_css) {
    "a.pivotal-logo {
  background: url(#{non_responsive_uri}) -1px -1px no-repeat;
}
a.pivotal-logo span {
  background: url(http://www.gopivotal.com/sites/all/themes/gopo13/images/pivotal-logo.png) -1px -48px no-repeat;
  background-image: url(http://www.gopivotal.com/sites/all/themes/gopo13/images/searchsprite.png);
  background-image: url(http://www.gopivotal.com/sites/all/themes/gopo13/images/searchsprite.png);
}"
  }
  around do |example|
    tmp = Dir.mktmpdir
    File.open(File.join(tmp, 'test.css'), 'w'){ |file| file.write(test_css) }
    Dir.chdir(tmp) do
      example.run
    end
  end

  describe 'when the remote URI does not respond' do
    before { Net::HTTP.stub(:get_response).with(URI(non_responsive_uri)).and_raise(SocketError) }
    it 'gets added to the list of broken links' do
      broken_links = []
      expect {
        broken_links = CssLinkChecker.new.broken_links_in_all_stylesheets
      }.not_to raise_error

      expect(broken_links).to include("test.css => #{non_responsive_uri}")
    end
  end
end