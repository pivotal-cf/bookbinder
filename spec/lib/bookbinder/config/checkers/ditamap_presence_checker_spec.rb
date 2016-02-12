require_relative '../../../../../lib/bookbinder/config/checkers/ditamap_presence_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    module Checkers
      describe DitamapPresenceChecker do
        context 'when there is a ditamap_location for each section' do
          it 'should return nil' do
            config = {
                'sections' => [
                  {'repository' => {
                    'name' => 'fantastic/non-dita-repo'}
                  }
                ],
                'dita_sections' =>
                    [
                        {'repository' => {
                            'name' => 'fantastic/dogs-repo'},
                         'ditamap_location' => 'my-special-location'
                        },
                        {'repository' => {
                            'name' => 'fobtastic/keyringrepo'},
                          'ditamap_location' => 'my-not-special-location'
                        }
                    ]

            }
            expect(DitamapPresenceChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end

        context 'when one or more sections are missing a ditamap_location' do
          it 'should return the correct error' do
            config = {
                'dita_sections' =>
                  [
                    {'repository' => {
                      'name' => 'fantastic/dogs-repo'},
                      'ditamap_location' => 'my-special-location'
                    },
                    {'repository' => {
                      'name' => 'fobtastic/keyringrepo'}
                    }
                  ]

            }
            expect(DitamapPresenceChecker.new.check(Configuration.parse(config)).class).
                to eq DitamapPresenceChecker::DitamapLocationError
          end
        end

        context 'when there are no dita_sections' do
          it 'returns nil' do
            config = {}
            expect(DitamapPresenceChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end
      end
    end
  end
end
