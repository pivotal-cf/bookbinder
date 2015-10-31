require_relative '../../../template_app/lib/vienna_application'

describe Bookbinder::Vienna::Application do
  it 'adds / to paths without them' do
    response = Bookbinder::Vienna::Application.new.call({'PATH_INFO' => '/foo/path'})
    expect(response).to eq [301, {"Location"=>"://::0/foo/path/", "Content-Type"=>""}, []]
  end
end
