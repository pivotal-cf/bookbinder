require 'webmock/rspec'

module WebConnection
  def only_local_web_allowed
    around do |example|
      net_connect_previously_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
      example.run
      WebMock.allow_net_connect! if net_connect_previously_allowed
    end
  end

  def web_allowed
    around do |example|
      net_connect_previously_allowed = WebMock.net_connect_allowed?
      WebMock.allow_net_connect!
      example.run
      WebMock.disable_net_connect!(allow_localhost: true) unless net_connect_previously_allowed
    end
  end
end
