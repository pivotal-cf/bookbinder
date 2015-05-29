require_relative '../../../../../lib/bookbinder/config/checkers/archive_menu_checker'

module Bookbinder
  module Config
    module Checkers
      describe ArchiveMenuChecker do
        context 'when there is an archive_menu key and the partial is present' do
          it 'return nil' do
            config = { 'archive_menu' => ['v1.3.0.0'] }
            fs_accessor = double('fs_accessor', file_exist?: true)

            expect(ArchiveMenuChecker.new(fs_accessor).check(config)).to be_nil
          end
        end

        context 'when there is an archive_menu key but the corresponding partial does not exist' do
          it 'returns the correct error' do
            valid_config_hash = { 'archive_menu' => ['v1.3.0.0'] }
            fs_accessor = double('fs_accessor', file_exist?: false)

            expect(ArchiveMenuChecker.new(fs_accessor).check(valid_config_hash).class).
                to eq ArchiveMenuChecker::MissingArchiveMenuPartialError
          end
        end

        context 'when there is no archive_menu key and no partial' do
          it 'returns nil' do
            config = {}
            fs_accessor = double('fs_accessor', file_exist?: false)

            expect(ArchiveMenuChecker.new(fs_accessor).check(config)).to be_nil
          end
        end

        context 'when there is an archive_menu but an item is empty' do
          it 'returns the correct error' do
            config = {
                'archive_menu' => [ nil ]
            }

            fs_accessor = double('fs_accessor', file_exist?: false)
            expect(ArchiveMenuChecker.new(fs_accessor).check(config).class).
                to eq ArchiveMenuChecker::EmptyArchiveItemsError
          end
        end

        context 'when there is an empty archive_menu key' do
          it 'returns the correct error' do
            config = { 'archive_menu' => nil }
            fs_accessor = double('fs_accessor', file_exist?: false)

            expect(ArchiveMenuChecker.new(fs_accessor).check(config).class).
                to eq ArchiveMenuChecker::ArchiveMenuNotDefinedError
          end
        end
      end
    end
  end
end
