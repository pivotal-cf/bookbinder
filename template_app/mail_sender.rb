require 'sendgrid-ruby'
require 'rack/response'
require 'uri'

module Bookbinder
  class MailSender
    def initialize(username, api_key, config={})
      @config = config
      @client = SendGrid::Client.new(api_user: username, api_key: api_key, raise_exceptions: false)
    end

    def send_mail(params)
      params = whitelisted_params(params)
      @subject = assemble_subject(params[:page_url])
      @body = assemble_body(**params)
      @mail = SendGrid::Mail.new(merged_options)

      response = client.send(@mail)
      Rack::Response.new(response.body, response.code, response.headers)
    end

    def assemble_subject(page_url)
      "[Feedback] New feedback submitted for #{URI.parse(page_url).host}"
    end

    def assemble_body(helpful: nil, comments: nil, date: nil, page_url: nil)
      <<-EOT
Date: #{date}

Page URL: #{page_url}

Helpful: #{helpful}

Comments:
#{comments}

      EOT
    end

    private

    attr_reader :config, :client

    def whitelist
      %w{helpful comments date page_url}
    end

    def whitelisted_params(params)
      {}.tap do |hash|
        params.each do |key, value|
          hash[key.to_sym] = value if whitelist.include?(key)
        end
      end
    end

    def merged_options
      config.merge({text: @body, subject: @subject})
    end

  end
end
