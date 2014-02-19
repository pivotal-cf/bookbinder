require_relative '../template_app/app.rb'

describe Vienna::Application do
  it 'adds / to paths without them' do
    response = Vienna::Application.new.call({'PATH_INFO' => '/foo/path'})
    response.should == [301, {"Location"=>"://::0/foo/path/", "Content-Type"=>""}, []]
  end
end
