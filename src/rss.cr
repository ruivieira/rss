require "http/client"
require "xml"
require "json"

module RSS
  extend self

  class Item
    include JSON::Serializable

    property title : String
    property link : String
    property pubDate : String # TODO: Converter??
    property comments : String
    property description : String
    property guid : String
    property author : String
    property category : String

    def initialize(@title = "", @link = "", @pubDate = "", @comments = "", @description = "", @guid = "", @author = "", @category = "")
    end
  end

  class Feed
    include JSON::Serializable

    property version : String
    property items : Array(Item)
    property title : String
    property link : String

    def initialize(@version = "2.0", @title = "", @link = "", @items = Array(Item).new)
    end

    def to_s
      "version: #{@version}"
    end
  end

  def parse(url : String) : Feed
    response = HTTP::Client.get url
    raise Exception.new("Non-200 response") if response.status != HTTP::Status::OK # TODO: Better request failed exception
    feed = XML.parse response.body

    result = Feed.new

    version = feed.first_element_child
    result.version = version["version"].to_s if version

    feed.xpath_node("/rss/channel/title").try { |n| result.title = n.content }
    feed.xpath_node("/rss/channel/link").try { |n| result.link = n.content }
    result.items = feed.xpath_nodes("//rss/channel/item").map do |c|
      Item.new.tap do |item|
        c.xpath_node("title").try { |n| item.title = n.content }
        c.xpath_node("link").try { |n| item.link = n.content }
        c.xpath_node("pubDate").try { |n| item.pubDate = n.content }
        c.xpath_node("description").try { |n| item.description = n.content }
        c.xpath_node("comments").try { |n| item.comments = n.content }
        c.xpath_node("guid").try { |n| item.guid = n.content }
        c.xpath_node("author").try { |n| item.author = n.content }
        c.xpath_node("category").try { |n| item.category = n.content }
      end
    end

    result
  end
end
