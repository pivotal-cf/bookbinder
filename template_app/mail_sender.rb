require 'sendgrid-ruby'
require 'rack/response'

module Bookbinder
  class MailSender
    def initialize(username, api_key, config={})
      @config = config
      @client = SendGrid::Client.new(api_user: username, api_key: api_key, raise_exceptions: false)
    end

    def send_mail(helpful:nil, comments:nil, date:nil, page_url:nil)
      @body = assemble_body(helpful, comments, date, page_url)
      @mail = SendGrid::Mail.new(merged_options)

      response = client.send(@mail)
      Rack::Response.new(response.body, response.code, response.headers)
    end

    def assemble_body(helpful, comments, date, page_url)
      <<-EOT
Dear docs writer,

You just received new feedback.

The sender thought the document was #{helpfulness(helpful)}.

Date: #{date}
Page URL: #{page_url}

Comments:
#{comments || "None given"}

Happy editing!
      EOT
    end

    private

    attr_reader :config, :client

    def merged_options
      config.merge({text: @body})
    end

    def helpfulness(was_helpful)
      was_helpful ? 'helpful' : 'not helpful'
    end
  end
end
