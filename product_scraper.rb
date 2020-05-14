require 'nokogiri'
require 'open-uri'
require 'json'

class ProductScraper

  def initialize(file_name, category_data)
    @product_data = {}
    @category_data = category_data
    @file = File.open("configs/#{file_name}.txt")
    @data = eval(@file.read)
    @file.close
    self.parse_data
  end

  def parse_data
    (0...@category_data.size).each do |index|
      product_scraper = Nokogiri::HTML(open(@category_data[index][:product_link]))
      name = product_scraper.xpath(@data[:product_scrape][:name_selector]).text.split(" ").join(" ")
      city = product_scraper.xpath(@data[:product_scrape][:city_selector]).text.split(" ").join(" ")
      condition = product_scraper.xpath(@data[:product_scrape][:condition_selector]).text.split(" ").join(" ")
      description = product_scraper.xpath(@data[:product_scrape][:description_selector]).text.split(" ").join(" ")
      seller_number = product_scraper.xpath(@data[:product_scrape][:seller_number_selector]).text.split(" ").join(" ")
      product_price = product_scraper.xpath(@data[:product_scrape][:product_price]).text.split(" ").join(" ")

      @product_data.store(index, {name: name, city: city, condition: condition, description: description, seller_number: seller_number, product_price: product_price})
    end
    self.get_data
  end

  def get_data
    @product_data.each_key do |index|
      puts @product_data[index]
    end
  end
end