require 'bookbinder_helpers'
require 'middleman-syntax'
require 'middleman-livereload'

config = YAML.load_file('bookbinder_config.yml')
config.each do |k, v|
  set k, v
end

set :markdown_engine, :redcarpet
set :markdown, :layout_engine => :erb,
               :tables => true,
               :autolink => true,
               :smartypants => true,
               :fenced_code_blocks => true

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

set :relative_links, false

activate :navigation

activate :syntax

activate :livereload
