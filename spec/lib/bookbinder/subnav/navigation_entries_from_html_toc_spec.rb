require_relative '../../../../lib/bookbinder/subnav/navigation_entries_from_html_toc'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Subnav
    describe NavigationEntriesFromHtmlToc do
      describe 'formatting a subnav' do
        let(:toc_html) { <<-EOT
<html>
  <body>
    <ul>
        <li><a href="common/topics/pivotal-copyright.html">Copyright</a></li>
        <li><a href="release-notes/release-notes.html">A. Pivotal GemFire XD 1.4 Release Notes</a>
            <ul>
                <li><a href="release-notes/release-notes-gemfirexd-1.4.0.html">A.i. Pivotal GemFire XD 1.4.0 Release Notes</a></li>
            </ul>
        </li>
    </ul>
  </body>
</html>
        EOT
        }

        let(:expected_navigation) {
          [
            {
              url: "/go-here-please/common/topics/pivotal-copyright.html",
              text: "Copyright"
            },
            {
              url: "/go-here-please/release-notes/release-notes.html",
              text: "A. Pivotal GemFire XD 1.4 Release Notes",
              nested_links: [
                {
                  url: "/go-here-please/release-notes/release-notes-gemfirexd-1.4.0.html",
                  text: "A.i. Pivotal GemFire XD 1.4.0 Release Notes"
                }
              ]
            }
          ]
        }

        it 'applies the appropriate CSS classes, wraps divs, and creates anchor paths from root' do
          section = Section.new(
            '',
            '',
            'go-here-please'
          )
          output_locations = OutputLocations.new(context_dir: '.')

          fs = instance_double('Bookbinder::LocalFilesystemAccessor')
          expect(fs).to receive(:read).with(
              File.join(output_locations.html_from_preprocessing_dir,'go-here-please','index.html')
          ) { toc_html }

          expect(NavigationEntriesFromHtmlToc.new(fs).get_links(section, output_locations)).to eq(expected_navigation)
        end
      end
    end
  end
end
