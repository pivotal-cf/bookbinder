require 'yaml'
require 'nokogiri'

require_relative '../helpers/use_fixture_repo'
require_relative '../helpers/redirection'

describe 'binding with the proof flag' do
  include Bookbinder::Redirection

  use_fixture_repo

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    config['sections'] = [{
    	'repository' => {
    		'name' 	=> 'fantastic/my-proofing-repo'	
    		},
    		'directory' => 'proof'
       }]

       File.write('./config.yml', config.to_yaml)
     end

     let(:gem_root) { File.expand_path('../../../', __FILE__) }

     it 'shows beginning and end of partial content and pages that use partial' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder bind local --proof`
      end

      contents = File.read(File.join('final_app', 'public', 'proof', 'file_that_calls_two_partials.html'))

      expect(contents).to include('BEGIN PARTIAL proof/_partial_one.erb')
      expect(contents).to include("CONTENTS OF '_partial_one.erb'")
      expect(contents).to include('END PARTIAL proof/_partial_one.erb')
      expect(contents).to include('BEGIN PARTIAL proof/_partial_two.erb')
      expect(contents).to include("CONTENTS OF '_partial_two.erb'")
      expect(contents).to include('END PARTIAL proof/_partial_two.erb')

      page = Nokogiri::HTML contents
      page.css('.partial-notice').each do |div|
        if div.text.include?('BEGIN PARTIAL proof/_partial_one.erb')
          expect(div.text).to include 'file_that_calls_just_one_partial'
          expect(div.text).to include 'file_that_calls_two_partials'
        elsif div.text.include?('BEGIN PARTIAL proof/_partial_two.erb')
          expect(div.text).to include 'file_that_calls_two_partials'
          expect(div.text).not_to include 'file_that_calls_just_one_partial'
        end
     end
   end
 end