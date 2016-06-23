require 'pathname'
require_relative 'fake_filesystem_accessor'

describe FakeFilesystemAccessor do
  it 'knows if a file exists' do
    fs = FakeFilesystemAccessor.new({ 'foo' => { 'bar' => { 'baz.html' => 'hi' }}})

    expect(fs.file_exist?('/foo/bar/baz.html')).to be true
    expect(fs.file_exist?(Pathname('/foo/bar/baz.html'))).to be true
    expect(fs.file_exist?('/foo/bar/quux.html')).to be false
  end

  it 'knows if something is a file' do
    fs = FakeFilesystemAccessor.new({ 'foo' => { 'bar' => { 'baz.html' => 'hi' }}})

    expect(fs.is_file?('/foo')).to be false
    expect(fs.is_dir?('/foo')).to be true

    expect(fs.is_file?('/foo/bar/baz.html')).to be true
    expect(fs.is_dir?('/foo/bar/baz.html')).to be false

    expect(fs.is_file?('/quux')).to be false
    expect(fs.is_dir?('/quux')).to be false

    expect(fs.is_file?('/foo/bar/quux.html')).to be false
    expect(fs.is_dir?('/foo/bar/quux.html')).to be false
  end

  it 'reads the contents of a file' do
    fs = FakeFilesystemAccessor.new({ 'foo' => { 'bar' => { 'baz.html' => 'hi' }}})

    expect(fs.read('/foo/bar/baz.html')).to eq('hi')
  end

  it 'finds files recursively' do
    fs = FakeFilesystemAccessor.new({
      'foo' => {
        'foo-baz' => 'things',
        'foo-biz' => 'others',
        'quux' => {
          'foo-quux' => 'that'
        }
      },
      'bar' => {
        'bar-baz' => 'stuff'
      }
    })

    expect(fs.find_files_recursively('/foo')).to eq([
      '/foo/foo-baz',
      '/foo/foo-biz',
      '/foo/quux/foo-quux'
    ])
  end

  it 'finds files with a specified extension recursively' do
    fs = FakeFilesystemAccessor.new({
      'foo' => {
        'foo.baz' => 'things',
        'foo.biz' => 'others',
        'quux' => {
          'bar.baz' => 'that'
        }
      },
      'bar' => {
        'bar-baz' => 'stuff'
      }
    })

    expect(fs.find_files_with_ext('baz', '/foo')).to eq([
      '/foo/foo.baz',
      '/foo/quux/bar.baz'
    ])
  end

  it 'can make a directory' do
    fs = FakeFilesystemAccessor.new({})

    fs.make_directory('/foo/bar/baz')

    expect(fs.is_dir?('/foo')).to be true
    expect(fs.is_dir?('/foo/bar')).to be true
    expect(fs.is_dir?('/foo/bar/baz')).to be true
  end

  it 'can make a directory where some ancestors exist' do
    fs = FakeFilesystemAccessor.new({
      'foo' => {
        'keep' => {},
        'bar' => {
          'baz' => {}
        }
      }
    })

    fs.make_directory('/foo/bar/quux')

    expect(fs.is_dir?('/foo')).to be true
    expect(fs.is_dir?('/foo/keep')).to be true
    expect(fs.is_dir?('/foo/bar')).to be true
    expect(fs.is_dir?('/foo/bar/baz')).to be true
    expect(fs.is_dir?('/foo/bar/quux')).to be true
  end

  context 'creating symlinks' do
    it 'has children available at the symlinked location' do
      fs = FakeFilesystemAccessor.new({
        'foo' => {
          'bar' => {
            'baz' => 'quux'
          }
        }
      })

      fs.link_creating_intermediate_dirs('/foo', '/place')

      expect(fs.is_dir?('/place')).to be true
      expect(fs.is_file?('/place/bar/baz')).to be true
    end

    it 'raises an error if the target already exists' do
      fs = FakeFilesystemAccessor.new({
        'foo' => {
          'bar' => {},
          'baz' => {}
        }
      })

      expect do
      fs.link_creating_intermediate_dirs('/foo/bar', '/foo/baz')
      end.to raise_exception(/already exists/)
    end
  end
end
