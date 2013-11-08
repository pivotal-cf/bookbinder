set :markdown_engine, :redcarpet
set :markdown, :layout_engine => :erb,
    :tables => true,
    :autolink => true,
    :smartypants => true,
    :fenced_code_blocks => true

configure :build do
  activate :relative_assets
  set :relative_links, true
end
