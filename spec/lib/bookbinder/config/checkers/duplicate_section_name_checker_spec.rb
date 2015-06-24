require_relative '../../../../../lib/bookbinder/config/checkers/duplicate_section_name_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    module Checkers
      describe DuplicateSectionNameChecker do
        describe 'validating the sections and dita_sections for duplicate names' do
          it 'should be valid when directory names are unique' do
            section1 = {
                'repository' => {
                    'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
                },
                'directory' => 'concepts'
            }

            section2 = {
                'repository' => {
                    'name' => 'cloudfoundry/docs-cloudfoundry-foo'
                },
                'directory' => 'foo'
            }

            section3 = {
                'repository' => {
                    'name' => 'cloudfoundry/docs-cloudfoundry-baz'
                },
                'ditamap_location' => 'something-else.ditamap'
            }

            section4 = {
                'repository' => {
                    'name' => 'cloudfoundry/docs-cloudfoundry-bar'
                },
                'ditamap_location' => 'something.ditamap'
            }

            valid_config_hash = {
                'sections' => [section1, section2],
                'dita_sections' => [section3, section4]
            }

            expect(DuplicateSectionNameChecker.new.check(Configuration.parse(valid_config_hash))).to be_nil
          end

          context 'when there are only sections' do
            it 'should be invalid when directory names are not unique' do
              section1 = {
                  'repository' => {
                      'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
                  },
                  'directory' => 'concepts'
              }

              invalid_config_hash = {
                  'sections' => [section1, section1]
              }

               expect(DuplicateSectionNameChecker.new.check(Configuration.parse(invalid_config_hash)).class).
                  to eq DuplicateSectionNameChecker::DuplicateSectionNameError
            end
          end

          context 'when there are only dita sections' do
            it 'should be invalid when directory names are not unique' do
              section1 = {
                  'repository' => {
                      'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
                  },
                  'directory' => 'concepts'
              }

              invalid_config_hash = {
                  'dita_sections' => [section1, section1]
              }

              expect(DuplicateSectionNameChecker.new.check(Configuration.parse(invalid_config_hash)).class).
                  to eq DuplicateSectionNameChecker::DuplicateSectionNameError
            end
          end

          context 'when there are both section and dita sections' do
            it 'should be invalid when directory names are not unique' do
              section1 = {
                  'repository' => {
                      'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
                  },
                  'directory' => 'concepts'
              }

              invalid_config_hash = {
                  'sections' => [section1],
                  'dita_sections' => [section1]
              }

              expect(DuplicateSectionNameChecker.new.check(Configuration.parse(invalid_config_hash)).class).
                  to eq DuplicateSectionNameChecker::DuplicateSectionNameError
            end
          end
        end
      end
    end
  end
end
