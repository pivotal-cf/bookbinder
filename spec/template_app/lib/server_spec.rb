require_relative '../../../template_app/lib/server'

describe Bookbinder::Server do
  it 'adds / to paths without them' do
    response = Bookbinder::Server.new.call({'PATH_INFO' => '/foo/path'})
    expect(response).to eq [301, {"Location"=>"://::0/foo/path/", "Content-Type"=>""}, []]
  end

  it 'adds a / to an empty path' do
    response = Bookbinder::Server.new.call({'PATH_INFO' => ''})
    expect(response).to eq [301, {"Location"=>"://::0/", "Content-Type"=>""}, []]
  end

  it 'does not add a / to an existing /' do
    Dir.chdir(File.expand_path('../../../fixtures/static_file_checking', __FILE__)) do
      response = Bookbinder::Server.new.call({'PATH_INFO' => '/'})
      expect(response.first).not_to eq(301)
    end
  end
end
