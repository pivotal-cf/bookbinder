require 'bookbinder_helpers'
require 'proof'
require 'middleman-syntax'
require 'middleman-livereload'
require 'middleman-sprockets'
require 'subdirectory_aware_assets'
require 'middleman-compass'
require 'font-awesome-sass'

config = YAML.load_file('bookbinder_config.yml')
config.each do |k, v|
  set k, v
end

set :markdown_engine, :redcarpet
set :markdown, :layout_engine => :erb,
               :tables => true,
               :autolink => true,
               :smartypants => true,
               :fenced_code_blocks => true,
               :with_toc_data => true,
               :no_intra_emphasis => true

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

set :relative_links, false

page '/owners.json', :layout => false

activate :bookbinder

activate :proof

activate :syntax

activate :livereload

activate :sprockets
import_path FontAwesome::Sass.fonts_path

activate :subdirectory_aware_assets
