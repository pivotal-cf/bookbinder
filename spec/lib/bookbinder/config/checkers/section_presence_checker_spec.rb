require_relative '../../../../../lib/bookbinder/config/checkers/section_presence_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    module Checkers
      describe SectionPresenceChecker do
        context 'when there are sections' do
          it 'should return nil' do
            config = {
              'sections' =>
                [
                  {'repository' => {
                    'name' => 'fantastic/dogs-repo'},
                    'ditamap_location' => 'my-special-location'
                  }
                ]

            }
            expect(SectionPresenceChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end

        context 'when there are no sections' do
          it 'should return the correct error' do
            config = { 'sections' => [] }
            expect(SectionPresenceChecker.new.check(Configuration.parse(config)).class).
              to eq SectionPresenceChecker::NoSectionsError
          end
        end
      end
    end
  end
end
