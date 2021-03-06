require 'nokogiri'
require 'open-uri'
require 'json'
require_relative 'send_mail'

class ProductScraper

  def initialize(file_name, category_data)
    @product_data = {}
    @category_data = category_data
    @file = File.open("configs/#{file_name}.txt")
    @config_data = eval(@file.read)
    @file.close
    self.parse_data
  end

  def parse_data
    (0...@category_data.size).each do |index|
      product_scraper = Nokogiri::HTML(open(@category_data[index][:product_link]))
      name = product_scraper.xpath(@config_data[:product_scrape][:name_extractor]).text.split(" ").join(" ")
      city = product_scraper.xpath(@config_data[:product_scrape][:city_extractor]).text.split(" ").join(" ")
      condition = product_scraper.xpath(@config_data[:product_scrape][:condition_extractor]).text.split(" ").join(" ")
      description = product_scraper.xpath(@config_data[:product_scrape][:description_extractor]).text.split(" ").join(" ")
      seller_number = product_scraper.xpath(@config_data[:product_scrape][:seller_number_extractor]).text.split(" ").join(" ")
      price = product_scraper.xpath(@config_data[:product_scrape][:product_price_extractor]).text.split(" ").join(" ")

      @product_data.store(index, {name: name, city: city, condition: condition, description: description, seller_number: seller_number, price: price, product_link: @category_data[index][:product_link]})
    end
    self.send_data_to_mail_sender
  end

  def send_data_to_mail_sender
    send_email = MailSender.new(@config_data, @product_data)
    send_email.detailed_mail
  end
end