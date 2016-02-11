require_relative '../../../../lib/bookbinder/config/dita_config_generator'

module Bookbinder
  module Config
    describe DitaConfigGenerator do
      describe '#ditamap_location' do
        it 'returns the ditamap location if provided' do
          expect(DitaConfigGenerator.new({'ditamap_location' => 'hdb-webhelp.ditamap'}).ditamap_location).
            to eq('hdb-webhelp.ditamap')
        end
        it 'returns nil if key not present' do
          expect(DitaConfigGenerator.new({}).ditamap_location).
            to be_nil
        end
        it 'returns nil if key is present but no value' do
          expect(DitaConfigGenerator.new({'ditamap_location' => ''}).ditamap_location).
            to be_nil
        end
      end

      describe '#pdf_output_filename' do
        it 'returns the output_filename when specified in the config' do
          section = {'output_filename' => 'our-pdf'}
          expect(DitaConfigGenerator.new(section).pdf_output_filename).to eq('our-pdf.pdf')
        end

        it 'returns the ditamap name if output_filename is not specified in config' do
          section = {'ditamap_location' => 'our-ditamap.ditamap'}
          expect(DitaConfigGenerator.new(section).pdf_output_filename).to eq('our-ditamap.pdf')
        end

        it 'returns nil if neither ditamap nor output_filename is specified in config' do
          section = {}
          expect(DitaConfigGenerator.new(section).pdf_output_filename).to be_nil
        end
      end

      describe '#preprocessor_config' do
        it 'nests ditamap and ditval values under a preprocessor key' do
          section = {'ditamap_location' => 'ditamap.ditamap', 'ditaval_location' => 'my.ditaval'}
          expect(DitaConfigGenerator.new(section).preprocessor_config).to eq(
              {'preprocessor_config' =>
                {'ditamap_location' => 'ditamap.ditamap', 'ditaval_location' => 'my.ditaval'} }
            )
        end
      end

      describe '#subnav_template_name' do
        it 'uses the desired directory name for subnav template when specified in config' do
          section = {'repository' => {'name' => 'org/repo-name1'},
                                      'directory' => 100,
                                      'ditamap_location' => 'ditamap-location'}

          expect(DitaConfigGenerator.new(section).subnav_template).to eq('dita_subnav_100')
        end

        it 'uses the ditamap name for subnav template if desired directory is not specified' do
          section = {'repository' => {'name' => 'org/repo-name1'},
                                      'ditamap_location' => 'ditamap-location'}

          expect(DitaConfigGenerator.new(section).subnav_template).to eq('dita_subnav_repo-name1')
        end
      end

      describe '#to_hash' do
        let(:dita_config) do
          section = {'repository' => {'name' => 'org/repo-name1'},
            'directory' => 100,
            'ditamap_location' => 'ditamap-location',
            'ditaval_location' => 'ditaval-location',
            'output_filename' => 'my-output-file' }

          DitaConfigGenerator.new(section).to_hash
        end

        it 'includes subnav template' do
          expect(dita_config['subnav_template']).to_not be_nil
        end

        it 'includes the output_filename' do
          expect(dita_config['output_filename']).to eq('my-output-file.pdf')
        end

        it 'moves ditamap and ditaval keys under preprocessor_config' do
          expect(dita_config['preprocessor_config'].keys).to include('ditamap_location', 'ditaval_location')
          expect(dita_config.keys).to_not include('ditamap_location', 'ditaval_location')
        end
      end
    end
  end
end
