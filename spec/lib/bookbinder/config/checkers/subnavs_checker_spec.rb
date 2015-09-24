require_relative '../../../../../lib/bookbinder/config/checkers/subnavs_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../lib/bookbinder/local_filesystem_accessor'

module Bookbinder
  module Config
    module Checkers
      describe SubnavsChecker do
        context 'when a subnav name is specified' do
          context 'when there is no subnavs key' do
            it 'returns an informative error' do
              config = {
                'sections' => [
                  {
                    'subnav_name' => 'subnav-group'
                  }
                ]
              }

              expect(SubnavsChecker.new.
                  check(Configuration.parse(config))).to be_a(SubnavsChecker::MissingSubnavsKeyError)
            end
          end

          context 'and the subnav group is not one of the subnav names' do
            it 'returns an informative error' do
              config = {
                'sections' => [
                  {
                    'subnav_name' => 'subnav-group'
                  }
                ],
                'subnavs' => [
                  { 'name' => 'fake-subnav-group' },
                  { 'name' => 'other-subnav-group' }
                ]
              }
              expect(SubnavsChecker.new.
                  check(Configuration.parse(config))).to be_a(SubnavsChecker::MissingSubnavNameError)
            end
          end

          context 'and the subnav group is in the subnavs key' do
            it 'returns nil' do
              config = {
                'sections' => [
                  { 'subnav_name' => 'subnav-group' },
                  { 'subnav_name' => 'other-group' }
                ],
                'subnavs' => [
                  { 'name' => 'other-group', 'topics' => [] },
                  { 'name' => 'subnav-group', 'topics' => [] }
                ]
              }
              expect(SubnavsChecker.new.
                  check(Configuration.parse(config))).to be_nil
            end
          end
        end

        context 'when a subnav group is not specified' do
          it 'returns nil' do
            config = {}
            expect(SubnavsChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end

        context 'when required keys are missing' do
          it 'returns an informative error' do
            config = {
              'sections' => [
                { 'subnav_name' => 'other-group' }
              ],
              'subnavs' => [
                { 'name' => 'other-group' }
              ]
            }

            expect(SubnavsChecker.new.check(Configuration.parse(config))).
              to be_a(SubnavsChecker::MissingRequiredKeyError)
          end
        end
      end
    end
  end
end
