require 'spec_helper'

describe '$ bookbinder publish' do
  include_context 'tmp_dirs'

  let(:config_body) do
    {
        'repos' => [
            {'github_repo' => 'foo/dogs-repo', 'directory' => 'temporarily-dogs'},
            {'github_repo' => 'baz/my-docs-repo', 'directory' => 'docs-for-now'},
        ],
        'template_variables' => {'a' => 'b'},
        'cloud_foundry' => { 'public_host' => 'example.com' }
    }.to_yaml
  end

  around do |example|
    `touch config.yml`
    `echo '#{config_body}' > config.yml`
    FileUtils.cp_r 'spec/fixtures/markdown_repos/my-docs-repo', '../'
    FileUtils.cp_r 'spec/fixtures/markdown_repos/dogs-repo', '../'
    example.run
    FileUtils.rm_rf '../my-docs-repo'
    FileUtils.rm_rf '../dogs-repo'
    `rm config.yml`
    `rm -rf final_app`
    `rm -rf output`
  end

  it 'generates a sinatra app' do
    `bundle exec bookbinder publish local`

    index_html = File.read File.join(APP_ROOT, 'final_app', 'public', 'docs-for-now', 'index.html')
    index_html.should include 'This is a Markdown Page'
  end

  it 'creates a PDF file'

  describe 'publish local' do
    it 'generates a sinatra app'

    context 'when no config.yml credentials are provided' do
      it 'generates a sinatra app'
    end
  end
end