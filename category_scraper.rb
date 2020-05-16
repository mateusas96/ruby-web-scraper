require 'nokogiri'
require 'open-uri'
require 'json'
require_relative 'product_scraper'
require_relative 'send_mail'

class CategoryScraper

  def initialize(file_name)
    @category_data = {}
    @web_pages = {}
    @filtered_category_data = {}
    @file_name = file_name
    file = File.open("configs/#{@file_name}.txt")
    @config_data = eval(file.read)
    file.close
    self.generate_pagination
  end

  def generate_pagination
    (@config_data[:category_scrape][:pagination][:start_number]..@config_data[:category_scrape][:pagination][:pagination_extractor]).each do |value|
      if @config_data[:category_scrape][:pagination][:pagination_generator].empty?
        @web_pages.store(value, @config_data[:category_scrape][:pagination][:put_pagination_in].gsub("PAGINATION", "#{value}"))
      else
        @web_pages.store(value, @config_data[:category_scrape][:pagination][:put_pagination_in].gsub("PAGINATION", "#{@config_data[:category_scrape][:pagination][:pagination_generator]}#{value}"))
      end
    end
    self.parse_data
  end

  def parse_data
    current_index = 0
    temp_hash = {}

    (0...@web_pages.length).each do |index|
      category_scraper = Nokogiri::HTML(open(@web_pages.values[index]))

      category_scraper.xpath(@config_data[:category_scrape][:preferred_city_selector]).each_with_index do |city, idx|
        if city.text.gsub(/[,.]/, '').strip != @config_data[:category_scrape][:desired_city] then break end
        temp_hash.store(current_index + idx, { name: '', price: '', city: city.text.gsub(/[,.]/, '').split(" ").join(" "), product_link: ''})
      end

      category_scraper.xpath(@config_data[:category_scrape][:name_selector]).each_with_index do |name ,idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:name] = name.text.split(" ").join(" ")
      end

      category_scraper.xpath(@config_data[:category_scrape][:price_selector]).each_with_index do |price, idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:price] = price.text.split(" ").join(" ").gsub(/[a-zA-ZąĄčČęĘėĖįĮšŠųŲūŪžŽ]/, '')
      end

      category_scraper.xpath(@config_data[:category_scrape][:product_href_selector]).each_with_index do |href, idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:product_link] = @config_data[:category_scrape][:web_urn_replacer] + href.text
      end

      @category_data = @category_data.merge(temp_hash)
      current_index = temp_hash.size
    end
    self.filter_unnecessary_data
  end

  def filter_unnecessary_data
    current_index = 0
    @category_data.each_key do |index|
      (0...@config_data[:category_scrape][:desired_product].length).each do |product|
        if !!(@category_data[index][:name] =~ /#{@config_data[:category_scrape][:desired_product][product]}/)
          if current_index != 0 && @filtered_category_data[current_index-1][:product_link] == @category_data[index][:product_link] then next end
          if @category_data[index][:price].gsub(@config_data[:category_scrape][:currency_symbol], '').split(" ").join("").to_i >= @config_data[:category_scrape][:desired_product_price] then next end
          @filtered_category_data.store(current_index,{name: @category_data[index][:name], price: @category_data[index][:price], city: @category_data[index][:city], product_link: @category_data[index][:product_link]})
          current_index += 1
        end
      end
    end
    self.detailed_info_about_product
  end

  def detailed_info_about_product
    if @config_data[:detailed_information_about_product]
      ProductScraper.new(@file_name,@filtered_category_data)
    else
      send_mail = MailSender.new(@config_data,@filtered_category_data)
      send_mail.standard_mail
    end
  end
end

puts "Enter file name:"
file_name = gets.chomp
CategoryScraper.new(file_name)