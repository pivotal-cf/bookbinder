require_relative '../../../../lib/bookbinder/validation_checkers/repository_name_presence_checker'

module Bookbinder
  describe RepositoryNamePresenceChecker do
    context 'when there are sections' do
      context 'and there are repositories with names' do
        it 'returns nil' do
          config = {
              'sections' =>
                  [
                      {
                          'directory' => 'some-cool-name',
                          'repository' => {
                              'name' => 'an-awesome-name'
                          }
                      }
                  ]
          }

          expect(RepositoryNamePresenceChecker.new.check(config)).
              to be_nil
        end
      end

      context 'and there are repositories but no names' do
        it 'returns the correct error' do
          config = {
              'sections' =>
                  [
                      {
                          'directory' => 'some-cool-name',
                          'repository' => {}
                      }
                  ]
          }

          expect(RepositoryNamePresenceChecker.new.check(config).class).
              to eq RepositoryNamePresenceChecker::MissingRepositoryNameError
          end
        end

      context 'and there are no repositories' do
        it 'returns the correct error' do
          config = {
              'sections' =>
                  [
                      {
                          'directory' => 'some-cool-name'
                      }
                  ]
          }

          expect(RepositoryNamePresenceChecker.new.check(config).class).
              to eq RepositoryNamePresenceChecker::MissingRepositoryNameError
        end
      end
    end

    context 'when there are dita sections' do
      context 'and there are repositories but no names' do
        it 'returns the correct error' do
        config = {
            'dita_sections' =>
                [
                    {
                        'directory' => 'some-cool-name',
                        'repository' => {}
                    }
                ]
        }

        expect(RepositoryNamePresenceChecker.new.check(config).class).
            to eq RepositoryNamePresenceChecker::MissingRepositoryNameError
        end
      end

      context 'and there are no repositories' do
        it 'returns the correct error' do
        config = {
            'dita_sections' =>
                [
                    {
                        'directory' => 'some-cool-name',
                    }
                ]
        }

        expect(RepositoryNamePresenceChecker.new.check(config).class).
            to eq RepositoryNamePresenceChecker::MissingRepositoryNameError
        end
      end
    end
  end
end
