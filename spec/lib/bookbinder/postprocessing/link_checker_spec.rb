require 'pathname'
require_relative '../../../../lib/bookbinder/postprocessing/link_checker'
require_relative '../../../helpers/fake_filesystem_accessor'

module Bookbinder
  module Postprocessing
    describe LinkChecker do
      let(:streams) do
        {
          out: StringIO.new,
          err: StringIO.new
        }
      end
      before do
        allow(Dir).to receive(:chdir) { [] }
      end

      it 'reports a broken link' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="foo.html">foo</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(checker).to have_errors
        errors = streams[:err].tap(&:rewind).read
        expect(errors).to include('/index.html => /foo.html')
        expect(errors).to include('Found 1 broken links!')
      end

      it 'reports success' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="foo.html">foo</a></div>',
              'foo.html' => '<div><a href="/index.html">index</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(streams[:err].tap(&:rewind).read).to eq('')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'ignores external links' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="http://example.com/foo.html">foo</a></div>',
              'foo.html' => '<div><a href="https://example.com/index.html">index</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        errors = streams[:err].tap(&:rewind).read
        expect(errors).not_to include('index.html')
        expect(errors).not_to include('/foo.html =>')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'ignores javascript links' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="javascript:void(0);">foo</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(streams[:err].tap(&:rewind).read).to eq('')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'ignores mailto links' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="mailto:foo@example.com">foo</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(streams[:err].tap(&:rewind).read).to eq('')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'ignores partials and helpers things' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              '404.html' => '<div><a href="/broken.html">foo</a></div>',
              'subnavs' => {
                'things.html' => '<div><a href="/broken.html">index</a></div>'
              },
              'javascripts' => {
                'things.html' => '<div><a href="/broken.html">index</a></div>'
              },
              'stylesheets' => {
                'things.html' => '<div><a href="/broken.html">index</a></div>'
              },
              'style_guide' => {
                'things.html' => '<div><a href="/broken.html">index</a></div>'
              },
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(streams[:err].tap(&:rewind).read).to eq('')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'allows links to redirected urls' do
        redirects = <<-RUBY
        r301 '/foo\.html', '/index.html'
        r302 %r{ba.\.html}, '/index.html'
        rewrite '/thing', '/index.html'
        RUBY

        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'redirects.rb' => redirects,
            'public' => {
              'index.html' => '<div><a href="/foo.html">foo</a><a href="/thing">Thing</a></div>',
              'thing.html' => '<div><a href="/bar.html">foo</a></div>',
              'think.html' => '<div><a href="/baz.html">foo</a></div>',
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        errors = streams[:err].tap(&:rewind).read
        expect(errors).not_to include '/thing.html =>'
        expect(errors).not_to include '/think.html =>'
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'ignores wildcard redirects with Procs' do
        redirects = <<-RUBY
        r302 %r{.*}, '/index.html', if: Proc.new {|foo| true}
        RUBY

        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'redirects.rb' => redirects,
            'public' => {
              'index.html' => '<div><a href="/foo.html">foo</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(checker).to have_errors
        errors = streams[:err].tap(&:rewind).read
        expect(errors).to include('/index.html => /foo.html')
      end

      it 'allows links to non-html files' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="/foo.pdf">foo</a></div>',
              'foo.pdf' => '00000000000000',
              'think.html' => '<div><a href="/baz.pdf">foo</a></div>',
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(checker).to have_errors
        errors = streams[:err].tap(&:rewind).read
        expect(errors).not_to include('/index.html')
        expect(errors).to include('/think.html => /baz.pdf')
      end

      it 'can exclude certain links' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="/ignored.html">foo</a></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!(/ignored/)

        expect(streams[:err].tap(&:rewind).read).to eq('')
        expect(checker).not_to have_errors
        expect(streams[:out].tap(&:rewind).read).to include('No broken links!')
      end

      it 'reports an orphaned page' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="/thing.html">foo</a></div>',
              'thing.html' => '<div></div>',
              'stuff.html' => '<div></div>'
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(checker).not_to have_errors
        errors = streams[:err].tap(&:rewind).read
        expect(errors).not_to include('index.html')
        expect(errors).not_to include('thing.html')
        expect(errors).to include('No links to => /stuff.html')
      end

      it 'finds an index.html for a folder link' do
        fs = FakeFilesystemAccessor.new({
          'finnish_app' => {
            'public' => {
              'index.html' => '<div><a href="/thing/">foo</a></div>',
              'stuff.html' => '<div><a href="/">index</a></div>',
              'thing' => {
                'not_index.html' => '<div></div>'
              }
            }
          }
        })
        checker = LinkChecker.new(fs, Pathname('/finnish_app'), streams)

        checker.check!

        expect(checker).to have_errors
        errors = streams[:err].tap(&:rewind).read
        expect(errors).to include("/index.html => /thing/")
        expect(errors).not_to include("/stuff.html =>")
      end
    end
  end
end
