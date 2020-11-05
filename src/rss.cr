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
    @[JSON::Field(converter: RSS::URIConverter)]
    property link : URI
    property description : String
    property items : Array(Item)

    # Optional Channel Elements
    property language : String?
    property copyright : String?
    property managingEditor : String?
    property webMaster : String?
    property pubDate : Time?
    property lastBuildDate : Time?
    property categories : Array(Category)?
    property generator : String?
    @[JSON::Field(converter: RSS::URIConverter)]
    property docs : URI?
    property cloud : Cloud?
    @[JSON::Field(converter: RSS::TimeSpanConverter)]
    property ttl : Time::Span?
    property image : Image?
    property rating : String?
    property textInput : TextInput?
    property skipHours : Array(UInt8)?
    property skipDays : Array(Time::DayOfWeek)?

    # Syndication RSS Module
    property updatePeriod : String?
    property updateFrequency : UInt32?
    property updateBase : Time?

    def initialize(@version = "", @title = "", @link = URI.new, @description = "", @items = Array(Item).new, @language = nil, @copyright = nil,
                   @managingEditor = nil, @webMaster = nil, @pubDate = nil, @lastBuildDate = nil, @categories = nil, @generator = nil, @docs = nil, @cloud = nil,
                   @ttl = nil, @image = nil, @textInput = nil, @skipHours = nil, @skipDays = nil)
    end

    def to_s
      "version: #{@version}"
    end

    # Check required fields
    def check
      raise ParserException.new("Invalid Version") if @version.empty?
      raise ParserException.new("Missing required title field") if @title.empty?
      raise ParserException.new("Missing required link filed") if @link == URI.new
      raise ParserException.new("Missing required description filed") if @description.empty?
      @items.each { |i| raise ParserException.new("Invalid item") if (i.title.nil? || i.title.not_nil!.empty?) && (i.description.nil? || i.description.not_nil!.empty?) }
      self
    end
  end

  def parse(url : String, max_redirects = 4)
    parse URI.parse(url), max_redirects
  end

  def parse(uri : URI, max_redirects = 4) : Feed
    feed = XML.parse getResponse(uri, max_redirects).body

    result = Feed.new

    raise ParserException.new("No rss tag in document root") if (rss = feed.xpath_node("/rss")).nil?
    raise ParserException.new("Invalid amount of channels") if feed.xpath_nodes("/rss/channel").size != 1

    rss.try { |c| c["version"]?.try { |v| result.version = v } }
    feed.xpath_node("/rss/channel/title").try { |n| result.title = URI.decode n.content }
    feed.xpath_node("/rss/channel/link").try { |n| result.link = (u = tryURI(n.content)).nil? ? raise ParserException.new("Invalid link field") : u }
    feed.xpath_node("/rss/channel/description").try { |n| result.description = URI.decode n.content }
    feed.xpath_node("/rss/channel/language").try { |n| result.language = n.content }
    feed.xpath_node("/rss/channel/copyright").try { |n| result.copyright = URI.decode n.content }
    feed.xpath_node("/rss/channel/managingEditor").try { |n| result.managingEditor = URI.decode n.content }
    feed.xpath_node("/rss/channel/webMaster").try { |n| result.webMaster = URI.decode n.content }
    feed.xpath_node("/rss/channel/pubDate").try { |n| result.pubDate = Time::Format::HTTP_DATE.parse n.content }
    feed.xpath_node("/rss/channel/lastBuildDate").try { |n| result.lastBuildDate = Time::Format::HTTP_DATE.parse n.content }
    result.categories = feed.xpath_nodes("/rss/channel/category").map { |n| Category.from_node n }
    feed.xpath_node("/rss/channel/generator").try { |n| result.generator = URI.decode n.content }
    feed.xpath_node("/rss/channel/docs").try { |n| result.docs = tryURI n.content }
    feed.xpath_node("/rss/channel/cloud").try { |n| result.cloud = Cloud.from_node n }
    feed.xpath_node("/rss/channel/ttl").try { |n| result.ttl = Time::Span.new(minutes: ((t = n.content.to_i) < 0 ? raise ParserException.new("Invalid ttl field") : t)) }
    feed.xpath_node("/rss/channel/image").try { |n| result.image = Image.from_node n }
    feed.xpath_node("/rss/channel/rating").try { |n| result.rating = n.content }
    feed.xpath_node("/rss/channel/textInput").try { |n| result.textInput = TextInput.from_node n }
    feed.xpath_node("/rss/channel/skipHours").try { |n| result.skipHours = n.xpath_nodes("hour").map { |h| (h = h.content.to_u8) < 24 ? h : raise ParserException.new("Invalid hour #{h}") }.uniq }
    feed.xpath_node("/rss/channel/skipDays").try { |n| result.skipDays = n.xpath_nodes("day").map { |d| getDayOfWeek d.content.downcase }.uniq }

    if rss.namespaces.has_key? "xmlns:sy"
      feed.xpath_node("/rss/channel/sy:updatePeriod").try { |n| result.updatePeriod = (["hourly", "daily", "weekly", "monthly", "yearly"].includes?(u = n.content.strip.downcase)) ? u : raise ParserException.new("Invalid sy:updatePeriod field") }
      feed.xpath_node("/rss/channel/sy:updateFrequency").try { |n| result.updateFrequency = (u = n.content.to_u32) == 0 ? raise ParserException.new("Invalid sy:updateFrequency field") : u }
      feed.xpath_node("/rss/channel/sy:updateBase").try { |n| result.updateBase = Time.parse n.content, "%Y-%m-%dT%R", Time::Location::UTC }
      if result.ttl.nil? && (!result.updatePeriod.nil? || !result.updateFrequency.nil?)
        freq = result.updateFrequency || 1
        result.ttl = case result.updatePeriod
                     when "daily"
                       Time::Span.new days: freq
                     when "monthly"
                       freq.months.from_now - Time.local.at_beginning_of_minute
                     when "yearly"
                       freq.years.from_now - Time.local.at_beginning_of_minute
                     else
                       Time::Span.new hours: freq
                     end
      end
    end

    result.items = feed.xpath_nodes("//rss/channel/item").map do |c|
      Item.new.tap do |item|
        c.xpath_node("title").try { |n| item.title = URI.decode n.content }
        c.xpath_node("link").try { |n| item.link = URI.parse n.content }
        c.xpath_node("description").try { |n| item.description = URI.decode n.content }
        c.xpath_node("author").try { |n| item.author = URI.decode n.content }
        item.categories = c.xpath_nodes("category").map { |n| Category.from_node n }
        c.xpath_node("comments").try { |n| item.comments = URI.parse n.content }
        c.xpath_node("enclosure").try { |n| item.enclosure = Enclosure.from_node n }
        c.xpath_node("guid").try { |n| item.guid = GUID.from_node n }
        c.xpath_node("pubDate").try { |n| item.pubDate = Time::Format::HTTP_DATE.parse n.content }
        c.xpath_node("source").try { |n| item.source = Source.from_node n }
      end
    end

    result.check
  end

  private def tryURI(content)
    begin
      URI.parse content
    rescue
      nil
    end
  end

  private def getDayOfWeek(content)
    case content
    when "tuesday"
      Time::DayOfWeek::Tuesday
    when "wednesday"
      Time::DayOfWeek::Wednesday
    when "thursday"
      Time::DayOfWeek::Thursday
    when "friday"
      Time::DayOfWeek::Friday
    when "saturday"
      Time::DayOfWeek::Saturday
    when "sunday"
      Time::DayOfWeek::Sunday
    else
      Time::DayOfWeek::Monday
    end
  end

  private def getResponse(uri : URI, redirects = 4)
    raise Exception.new("Too many redirects") if redirects == -1
    response = HTTP::Client.get uri
    return getResponse URI.parse(response.headers["Location"]), redirects - 1 if [300, 301, 302, 303, 307, 308].includes?(response.status_code) && response.headers.has_key?("Location")
    raise Exception.new("Server responded with #{response.status_code} #{response.status}") if !response.success?
    response
  end
end
