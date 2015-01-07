require_relative '../../../lib/bookbinder/css_link_checker'
require 'tmpdir'

module Bookbinder
  describe CssLinkChecker do
    let(:tmp) { Dir.mktmpdir }
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

    before do
      FileUtils.mkdir_p(File.join(tmp,'public/stylesheets/all/themes/gopo13/images/'))
      FileUtils.touch "#{tmp}/public/stylesheets/all/themes/gopo13/images/pivotal-logo.png"
      allow(Net::HTTP).to receive(:get_response).with(URI(non_responsive_uri)).and_raise(SocketError)
    end

    around do |example|
      Dir.chdir(tmp) do
        example.run
      end
    end

    context 'when the URI is relative' do
      describe 'to the current directory' do
        let(:relative_path) { "all/themes/gopo13/images/pivotal-logo.png" }
        let(:test_css) {
          "a.pivotal-logo {
            background: url(#{relative_path}) -1px -1px no-repeat;
          }"
        }

        before do
          FileUtils.mkdir_p(File.join(tmp,'public/stylesheets'))
          File.open(File.join(tmp, 'public/stylesheets/test.css'), 'w'){ |file| file.write(test_css) }
        end

        it 'correctly computes the relative path' do
          broken_links = []
          expect {
            broken_links = CssLinkChecker.new.broken_links_in_all_stylesheets
          }.not_to raise_error

          expect(broken_links).to be_empty
        end
      end

      describe 'to an upstream relative' do
        let(:upward_path) { "../../all/themes/gopo13/images/pivotal-logo.png" }
        let(:test_css) {
          "a.pivotal-logo {
            background: url(#{upward_path}) -1px -1px no-repeat;
          }"
        }
        before do
          FileUtils.mkdir_p(File.join(tmp,'public/stylesheets/some/dir'))
          File.open(File.join(tmp, 'public/stylesheets/some/dir/test.css'), 'w'){ |file| file.write(test_css) }
        end

        it 'correctly computes the relative path' do
          broken_links = []
          expect {
            broken_links = CssLinkChecker.new.broken_links_in_all_stylesheets
          }.not_to raise_error

          expect(broken_links).to be_empty
        end
      end

      describe 'and it contains extra quotes' do
        let(:single_quoted_path) { "'../../all/themes/gopo13/images/pivotal-logo.png'" }
        let(:double_quoted_path) { "\"../../all/themes/gopo13/images/pivotal-logo.png\"" }
        let(:test_css) {
          "a.pivotal-logo {
            background: url(#{single_quoted_path}) -1px -1px no-repeat;
          }
          a.pivotal-logo {
            background: url(#{double_quoted_path}) -1px -1px no-repeat;
          }"
        }
        before do
          FileUtils.mkdir_p(File.join(tmp,'public/stylesheets/some/dir'))
          File.open(File.join(tmp, 'public/stylesheets/some/dir/test.css'), 'w'){ |file| file.write(test_css) }
        end

        it 'correctly removes the quotes and computes the path' do
          broken_links = []
          expect {
            broken_links = CssLinkChecker.new.broken_links_in_all_stylesheets
          }.not_to raise_error

          expect(broken_links).to be_empty
        end
      end
    end

    describe 'when the remote URI does not respond' do
      before do
        FileUtils.mkdir_p(File.join(tmp,'public/stylesheets'))
        File.open(File.join(tmp, 'public/stylesheets/test.css'), 'w'){ |file| file.write(test_css) }
      end
      it 'gets added to the list of broken links' do
        broken_links = []
        expect {
          broken_links = CssLinkChecker.new.broken_links_in_all_stylesheets
        }.not_to raise_error

        expect(broken_links).to include("public/stylesheets/test.css => #{non_responsive_uri}")
      end
    end
  end
end
