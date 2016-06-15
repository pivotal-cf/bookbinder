require 'pathname'
require_relative 'fake_filesystem_accessor'

describe FakeFilesystemAccessor do
  it 'knows if a file exists' do
    fs = FakeFilesystemAccessor.new({ 'foo' => { 'bar' => { 'baz.html' => 'hi' }}})

    expect(fs.file_exist?('/foo/bar/baz.html')).to be true
    expect(fs.file_exist?(Pathname('/foo/bar/baz.html'))).to be true
    expect(fs.file_exist?('/foo/bar/quux.html')).to be false
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
end
