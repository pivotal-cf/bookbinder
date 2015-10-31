require 'pathname'
require './rack_app'
require './mail_sender'

mail_client = Bookbinder::MailSender.new(ENV['BOOKBINDER_SENDGRID_USER'], ENV['BOOKBINDER_SENDGRID_API_KEY'])

run Bookbinder::RackApp.new(Pathname('redirects.rb'), mail_client).app
