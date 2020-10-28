require "http/client"
require "xml"
require "json"
require "./models"

module RSS
  class Feed
    include JSON::Serializable

    # Required Channel Elements
    property version : String
    property title : String
    property link : URI
    property description : String
    property items : Array(Item)

    # Optional Channel Elements
    #

    def initialize(@version = "", @title = "", @link = URI.new, @description = "", @items = Array(Item).new)
    end

    def to_s
      "version: #{@version}"
    end

    # Make sure that the RSS Feed is up to specification
    def check
      raise ParserException.new("Invalid Version") if @version.empty?
      raise ParserException.new("Missing required title field") if @title.empty?
      raise ParserException.new("Missing required link filed") if @link == URI.new
      raise ParserException.new("Missing required description filed") if @description.empty?
      @items.each { |i| raise ParserException.new("Invalid item") if (i.title.nil? || i.title.not_nil!.empty?) && (i.description.nil? || i.description.not_nil!.empty?) }
      self
    end
  end

  def parse(url : String) : Feed
    response = HTTP::Client.get url
    raise Exception.new("Non-200 response") if response.status != HTTP::Status::OK # TODO: Better request failed exception
    feed = XML.parse response.body

    result = Feed.new

    feed.first_element_child.try { |c| c["version"]?.try { |v| result.version = v } }
    feed.xpath_node("/rss/channel/title").try { |n| result.title = n.content }
    feed.xpath_node("/rss/channel/link").try do |n|
      begin
        result.link = URI.parse n.content
      rescue
        raise ParserException.new("Invalid link field")
      end
    end
    feed.xpath_node("/rss/channel/description").try { |n| result.description = n.content }
    result.items = feed.xpath_nodes("//rss/channel/item").map do |c|
      Item.new.tap do |item|
        c.xpath_node("title").try { |n| item.title = n.content }
        c.xpath_node("link").try do |n|
          begin
            item.link = URI.parse n.content
          rescue
          end
        end
        c.xpath_node("pubDate").try { |n| item.pubDate = Time::Format::HTTP_DATE.parse n.content }
        c.xpath_node("description").try { |n| item.description = n.content }
        c.xpath_node("comments").try do |n|
          begin
            item.comments = URI.parse n.content
          rescue
          end
        end
        c.xpath_node("enclosure").try { |n| item.enclosure = Enclosure.from_node n }
        c.xpath_node("guid").try { |n| item.guid = GUID.from_node n }
        c.xpath_node("author").try { |n| item.author = n.content }
        c.xpath_node("category").try { |n| item.category = Category.from_node n }
      end
    end

    result.check
  end
end
