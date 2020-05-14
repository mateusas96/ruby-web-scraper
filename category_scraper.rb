require 'nokogiri'
require 'open-uri'
require 'json'
require_relative 'product_scraper'

class CategoryScraper

  def initialize(file_name)
    @category_data = {}
    @data = {}
    @web_pages = {}
    @file_name
    @filtered_category_data = {}
    @file_name = file_name
    file = File.open("configs/#{@file_name}.txt")
    @data = eval(file.read)
    file.close
    self.generate_pagination
  end

  def generate_pagination
    (@data[:category_scrape][:pagination][:start_number]..@data[:category_scrape][:pagination][:pagination_extractor]).each do |value|
      if @data[:category_scrape][:pagination][:pagination_generator].empty?
        @web_pages.store(value, @data[:category_scrape][:pagination][:put_pagination_in].gsub("PAGINATION", "#{value}"))
      else
        @web_pages.store(value, @data[:category_scrape][:pagination][:put_pagination_in].gsub("PAGINATION", "#{@data[:category_scrape][:pagination][:pagination_generator]}#{value}"))
      end
    end
    self.parse_data
  end

  def parse_data
    current_index = 0
    temp_hash = {}

    (0...@web_pages.length).each do |index|
      category_scraper = Nokogiri::HTML(open(@web_pages.values[index]))

      category_scraper.xpath(@data[:category_scrape][:preferred_city_selector]).each_with_index do |city, idx|
        if city.text.gsub(/[,.]/, '').strip != @data[:category_scrape][:desired_city] then break end
        temp_hash.store(current_index + idx, { name: '', price: '', city: city.text.gsub(/[,.]/, '').split(" ").join(" "), product_link: ''})
      end

      category_scraper.xpath(@data[:category_scrape][:name_selector]).each_with_index do |name ,idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:name] = name.text.split(" ").join(" ")
      end

      category_scraper.xpath(@data[:category_scrape][:price_selector]).each_with_index do |price, idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:price] = price.text.split(" ").join(" ").gsub(/[a-zA-ZąĄčČęĘėĖįĮšŠųŲūŪžŽ]/, '')
      end

      category_scraper.xpath(@data[:category_scrape][:product_href_selector]).each_with_index do |href, idx|
        if (current_index + idx) === temp_hash.size then break end
        temp_hash[current_index + idx][:product_link] = @data[:category_scrape][:web_urn_replacer] + href.text
      end

      @category_data = @category_data.merge(temp_hash)
      current_index = temp_hash.size
    end
    self.filter_unnecessary_data
  end

  def filter_unnecessary_data
    current_index = 0
    @category_data.each_key do |index|
      (0...@data[:category_scrape][:desired_product].length).each do |product|
        if !!(@category_data[index][:name] =~ /#{@data[:category_scrape][:desired_product][product]}/)
          if current_index != 0 && @filtered_category_data[current_index-1][:product_link] == @category_data[index][:product_link] then next end
          if @category_data[index][:price].gsub(@data[:category_scrape][:currency_symbol], '').split(" ").join("").to_i >= @data[:category_scrape][:desired_product_price] then next end
          @filtered_category_data.store(current_index,{name: @category_data[index][:name], price: @category_data[index][:price], city: @category_data[index][:city], product_link: @category_data[index][:product_link]})
          current_index += 1
        end
      end
    end
    self.detailed_info_about_product
  end

  def detailed_info_about_product
    if !!@data[:detailed_information_about_product]
      ProductScraper.new(@file_name,@filtered_category_data)
    else
      #send email
      puts "Email sent!"
    end
  end
end

puts "Enter file name:"
file_name = gets.chomp
puts
CategoryScraper.new(file_name)