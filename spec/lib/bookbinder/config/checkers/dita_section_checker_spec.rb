require_relative '../../../../../lib/bookbinder/config/checkers/dita_section_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    module Checkers
      describe DitaSectionChecker do
        context 'when there is at least one ditamap_location' do
          it 'should return nil' do
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
            expect(DitaSectionChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end

        context 'when there is no ditamap_location' do
          it 'should return the correct error' do
            config = {
                'dita_sections' =>
                    [
                        {'repository' => {
                            'name' => 'fantastic/dogs-repo'}
                        }
                    ]

            }
            expect(DitaSectionChecker.new.check(Configuration.parse(config)).class).
                to eq DitaSectionChecker::DitamapLocationError
          end
        end

        context 'when there are no dita_sections' do
          it 'returns nil' do
            config = {}
            expect(DitaSectionChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end
      end
    end
  end
end
