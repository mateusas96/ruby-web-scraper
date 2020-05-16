require 'sendgrid-ruby'
include SendGrid
require 'dotenv'

class MailSender

  def initialize(config_data, product_info)
    Dotenv.load('sendgrid.env')
    @config_data = config_data
    @product_info = product_info
  end

  def create_html_email_content
    html_content = "<h3>Hello!</h3><br>Product(-s) I have found:"
    if @config_data[:detailed_information_about_product]
      (0...@product_info.size).each do |index|
        html_content += "<br><br><b>Product nr. #{index+1}:</b>
                        <br><b>Name:</b> #{@product_info[index][:name]},
                        <br><b>City:</b> #{@product_info[index][:city]},
                        <br><b>Condition:</b> #{@product_info[index][:condition]},
                        <br><b>Description:</b> #{@product_info[index][:description]},
                        <br><b>Price:</b> #{@product_info[index][:product_price]},
                        <br><b>Seller number:</b> #{@product_info[index][:seller_number]},
                        <br><b>Product link:</b> <a href=\"#{@product_info[index][:product_link]}\">Click</a>"
      end
    else
      (0...@product_info.size).each do |index|
        html_content += "<br><br><b>Product nr. #{index+1}:</b>
                        <br><b>Name:</b> #{@product_info[index][:name]},
                        <br><b>City:</b> #{@product_info[index][:city]},
                        <br><b>Price:</b> #{@product_info[index][:price]},
                        <br><b>Product link:</b> <a href=\"#{@product_info[index][:product_link]}\">Click</a>"
      end
    end
    html_content
  end

  def standard_mail
    from = SendGrid::Email.new(email: 'scraperruby@gmail.com')
    to = SendGrid::Email.new(email: ENV['MY_EMAIL'])
    subject = 'I have found something that you might like'
    content = SendGrid::Content.new(type: 'text/html', value: self.create_html_email_content)
    mail = SendGrid::Mail.new(from, subject, to, content)

    self.send_mail(mail)
  end

  def detailed_mail
    from = SendGrid::Email.new(email: 'scraperruby@gmail.com')
    to = SendGrid::Email.new(email: ENV['MY_EMAIL'])
    subject = 'I have found something that you might like'
    content = SendGrid::Content.new(type: 'text/html', value: self.create_html_email_content)
    mail = SendGrid::Mail.new(from, subject, to, content)

    self.send_mail(mail)
  end

  def send_mail(mail)
    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
