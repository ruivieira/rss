require "http/client"
require "xml"

module RSS
  extend self

  class Item
    property title, link, pubDate, comments, description, guid

    def initialize
      @title = ""
      @link = ""
      @pubDate = ""
      @comments = ""
      @description = ""
      @guid = ""
    end
  end

  class Feed
    property version, items

    def initialize
      @version = "2.0"
      @items = Array(Item).new
    end

    def to_s
      s = "version: #{@version}"
      return s
    end
  end

  def parse(url : String) : Feed
    response = HTTP::Client.get url
    body = response.body
    feed = XML.parse(body)

    result = Feed.new

    version = feed.first_element_child
    if version
      result.version = version.as(XML::Node)["version"].as(String)
    end

    items = feed.xpath("//rss/channel/item").as(XML::NodeSet)
    result.items = items.map { |c|
      item = Item.new
      field = c.xpath_node("title")
      if field
        item.title = field.as(XML::Node).text.as(String)
      end

      field = c.xpath_node("link")
      if field
        item.link = field.as(XML::Node).text.as(String)
      end

      field = c.xpath_node("pubDate")
      if field
        item.pubDate = field.as(XML::Node).text.as(String)
      end

      field = c.xpath_node("description")
      if field
        item.description = field.as(XML::Node).text.as(String)
      end

      field = c.xpath_node("comments")
      if field
        item.comments = field.as(XML::Node).text.as(String)
      end

      field = c.xpath_node("guid")
      if field
        item.guid = field.as(XML::Node).text.as(String)
      end

      item
    }

    return result
  end
end
