require_relative '../../../../lib/bookbinder/validation_checkers/required_keys_checker'

module Bookbinder
  describe RequiredKeysChecker do
    context 'when the required keys are present' do
      it 'returns nil' do
        config = {
              'book_repo' => %w(v1.7.1.9 redacted v3),
              'public_host' => 'special/host',
              'sections' => []
          }

        expect(RequiredKeysChecker.new.check(config)).to be_nil
      end
    end

    context 'when a required key is missing' do
      it 'raises missing key error' do
        config = { 'versions' => %w(v1.7.1.9 redacted v3) }

        expect(RequiredKeysChecker.new.check(config).class).
            to eq RequiredKeysChecker::MissingRequiredKeyError
      end

      context 'when there are no sections or dita sections' do
        it 'should return the correct error' do
          config_hash = {
              'book_repo' => 'fantastic/fixture-book-title',
              'cred_repo' => 'fantastic/creds-repo',
              'public_host' => 'docs.example.com',
          }

          expect(RequiredKeysChecker.new.check(config_hash).class).
              to eq RequiredKeysChecker::SectionAbsenceError
        end
      end
    end
  end
end