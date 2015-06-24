require_relative '../../../../../lib/bookbinder/config/checkers/required_keys_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    module Checkers
      describe RequiredKeysChecker do
        context 'when the required keys are present' do
          it 'returns nil' do
            config = {
              'book_repo' => %w(v1.7.1.9 redacted v3),
              'public_host' => 'special/host',
              'sections' => []
            }

            expect(RequiredKeysChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end

        context 'when a required key is missing' do
          it 'raises missing key error' do
            config = { 'versions' => %w(v1.7.1.9 redacted v3) }

            expect(RequiredKeysChecker.new.check(Configuration.parse(config)).class).
              to eq RequiredKeysChecker::MissingRequiredKeyError
          end
        end
      end
    end
  end
end
