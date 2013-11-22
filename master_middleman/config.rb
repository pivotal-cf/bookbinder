require 'bookbinder_helpers'
require 'submodule_aware_assets'

set :markdown_engine, :redcarpet
set :markdown, :layout_engine => :erb,
               :tables => true,
               :autolink => true,
               :smartypants => true,
               :fenced_code_blocks => true

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

configure :build do
  # TODO: why is this stuff build-specific?
  set :relative_links, true
  activate :submodule_aware_assets
end

activate :navigation

