require_relative '../../template_app/mail_sender'
require 'sendgrid-ruby'
require 'rack/response'

module Bookbinder
  describe MailSender do
    it 'initializes SendGrid client' do
      expect(SendGrid::Client).to receive(:new).with(
          api_user: 'username',
          api_key: 'api-key',
          raise_exceptions: false
      )

      MailSender.new('username', 'api-key')
    end

    describe '#send_mail' do
      it 'sends SendGrid mail object with whitelisted parameters and returns its response' do
        mail_object = instance_double('SendGrid::Mail')
        client = instance_double('SendGrid::Client')
        sendgrid_response = double('sendgrid response', body: 'stuff', code: '1000', headers: ['A', 'Great'])

        allow(SendGrid::Client).to receive(:new) { client }

        allow(SendGrid::Mail).to receive(:new).with(
            to: 'recipient@email.com',
            from: 'sender@email.com',
            text: 'some text') { mail_object }

        expect(client).to receive(:send).with(mail_object) { sendgrid_response }
        expect(Rack::Response).to receive(:new).with('stuff', '1000', ['A', 'Great']) { 'I was sent' }

        sender = MailSender.new(
          'username',
          'api-key',
          to: 'recipient@email.com',
          from: 'sender@email.com'
        )
        allow(sender).to receive(:assemble_body).with(
            helpful: 'yes',
            comments: 'I love it',
            date: 'the future',
            page_url: 'the page') { 'some text' }

        expect(sender.send_mail({'helpful' => 'yes',
              'comments' => 'I love it',
              'date' => 'the future',
              'page_url' => 'the page',
              'extra parameter' => 'I do not belong'})).to eq('I was sent')
      end
    end

    describe '#assemble_body' do
      it 'should create body text' do
        sender = MailSender.new('username', 'api-key')

        expect(sender.assemble_body(
          helpful: true,
          comments: 'This is the actual feedback',
          date: 'Feb 14, 2050',
          page_url: 'http://some/page.html'
        )).to include('was helpful', 'This is the actual feedback', 'Feb 14, 2050', 'http://some/page.html')
      end
    end
  end
end
