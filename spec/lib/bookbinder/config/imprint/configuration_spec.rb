require_relative '../../../../../lib/bookbinder/config/imprint/configuration'
require_relative '../../../../../lib/bookbinder/config/dita_config_generator'

module Bookbinder
  module Config
    module Imprint
      describe Configuration do
        describe '.parse' do
          it 'uses only pdf sections' do
            config_generator = instance_double(DitaConfigGenerator)
            allow(DitaConfigGenerator).to receive(:new).with(
                {'repository' => {'name' => 'must/be-github'},
                  'ditamap_location' => 'my-pdf.ditamap',
                  'ditaval_location' => 'pdf-filter.ditaval'}) { config_generator }
            allow(config_generator).to receive(:to_hash) { {'my' => 'pdf-section'} }

            config = Configuration.parse(
              'sections' => [
                {'repository' => {'name' => 'must/be-github'}},
              ],
              'dita_sections' => [
                {'repository' => {'name' => 'must/be-github'},
                  'ditamap_location' => 'example.ditamap',
                  'ditaval_location' => 'dita-filter.ditaval'}
              ],
              'pdf_sections' => [
                {'repository' => {'name' => 'must/be-github'},
                  'ditamap_location' => 'my-pdf.ditamap',
                  'ditaval_location' => 'pdf-filter.ditaval'}
              ]
            )

            expect(config.sections.size).to eq(1)
            expect(config.sections[0]).to eq(Config::SectionConfig.new({'my' => 'pdf-section'}))
          end
        end
      end
    end
  end
end
