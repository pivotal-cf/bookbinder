require_relative '../../../template_app/lib/server'

describe Bookbinder::Server do
  it 'adds / to paths without them' do
    response = Bookbinder::Server.new.call({'PATH_INFO' => '/foo/path'})
    expect(response).to eq [301, {"Location"=>"://::0/foo/path/", "Content-Type"=>""}, []]
  end
end
