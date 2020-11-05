module RSS
  extend self

  class ParserException < Exception
  end

  class Item
    include JSON::Serializable

    property title : String?
    @[JSON::Field(converter: RSS::URIConverter)]
    property link : URI?
    property description : String?
    property author : String?
    property categories : Array(Category)?
    @[JSON::Field(converter: RSS::URIConverter)]
    property comments : URI?
    property enclosure : Enclosure?
    property guid : GUID?
    property pubDate : Time?
    property source : Source?

    def initialize(@title = nil, @link = nil, @pubDate = nil, @comments = nil, @description = nil, @guid = nil, @author = nil, @categories = nil, @enclosure = nil, @source = nil)
    end
  end

  struct GUID
    include JSON::Serializable

    property content : String
    property permaLink : Bool

    def initialize(@content, @permaLink = false)
    end

    def to_s
      @content
    end

    def self.from_node(node : XML::Node)
      GUID.new node.content, (i = node["isPermaLink"]?).nil? ? false : i == "true"
    end
  end

  struct Category
    include JSON::Serializable

    property content : String
    property domain : String

    def initialize(@content, @domain = "")
    end

    def to_s
      @content
    end

    def self.from_node(node : XML::Node)
      Category.new node.content, (d = node["domain"]?).nil? ? "" : d
    end
  end

  struct Enclosure
    include JSON::Serializable

    @[JSON::Field(converter: RSS::URIConverter)]
    property url : URI
    property length : UInt64
    property type : String

    def initialize(@url, @length, @type)
    end

    def to_s
      ""
    end

    def self.from_node(node : XML::Node)
      Enclosure.new URI.parse(node["url"]), node["length"].to_u64, node["type"]
    end
  end

  struct Source
    include JSON::Serializable

    property content : String
    @[JSON::Field(converter: RSS::URIConverter)]
    property url : URI

    def initialize(@content, @url)
    end

    def to_s
      @content
    end

    def self.from_node(node : XML::Node)
      Source.new node.content, (u = node["url"]?).nil? ? URI.new : URI.parse(u)
    end
  end

  struct Cloud
    include JSON::Serializable

    property domain : String
    property port : UInt16
    property path : String
    property registerProcedure : String
    property protocol : String

    def initialize(@domain, @port, @path, @registerProcedure, @protocol)
    end

    def to_s
      ""
    end

    def self.from_node(node : XML::Node)
      Cloud.new node["domain"], node["port"].to_u16, node["path"], node["registerProcedure"], node["protocol"]
    end
  end

  struct Image
    include JSON::Serializable

    @[JSON::Field(converter: RSS::URIConverter)]
    property url : URI
    property title : String
    @[JSON::Field(converter: RSS::URIConverter)]
    property link : URI
    # Optional elements
    property width : UInt32
    property height : UInt32
    property description : String

    def initialize(@url, @title, @link, @width = 88_u32, @height = 31_u32, @description = "")
    end

    def to_s
      ""
    end

    def self.from_node(node : XML::Node)
      url = URI.parse node.xpath_node("url").not_nil!.content
      title = URI.decode node.xpath_node("title").not_nil!.content
      link = URI.parse node.xpath_node("link").not_nil!.content
      width = node.xpath_node("width").try { |n| n.content.to_u32 }
      height = node.xpath_node("height").try { |n| n.content.to_u32 }
      desc = node.xpath_node("description").try { |n| URI.decode n.content }
      Image.new url, title, link, (width.nil? ? 88_u32 : width), (height.nil? ? 31_u32 : height), (desc.nil? ? "" : desc)
    end
  end

  struct TextInput
    include JSON::Serializable

    property title : String
    property description : String
    property name : String
    @[JSON::Field(converter: RSS::URIConverter)]
    property link : URI

    def initialize(@title, @description, @name, @link)
    end

    def to_s
      ""
    end

    def self.from_node(node : XML::Node)
      title = node.xpath_node("title").not_nil!.content
      desc = node.xpath_node("description").not_nil!.content
      name = node.xpath_node("name").not_nil!.content
      link = URI.parse node.xpath_node("link").not_nil!.content
      raise ParserException.new("Invalid name field in textInput") if !name.matches?(/[\w\d:._-]*/)
      TextInput.new title, URI.decode(desc), name, link
    end
  end

  module URIConverter
    def self.from_json(value : JSON::PullParser) : URI
      URI.parse value.read_string
    end

    def self.to_json(value : URI, json : JSON::Builder)
      json.string value.to_s
    end
  end

  module TimeSpanConverter
    def self.from_json(value : JSON::PullParser) : Time::Span
      di = (ni = 0) - 1
      if (tsp = value.read_string.split '.').size == 2
        tsp[0].includes?(':') ? (ni = -1) : (di = 0)
      elsif tsp.size == 3
        (di = (ni = di) + 1)
      end
      Time::Span.new days: (di == -1 ? 0 : tsp[di].to_i), hours: (rsp = tsp[(di == 0 ? 1 : 0)].split ':')[0].to_i, minutes: rsp[1].to_i, seconds: rsp[2].to_i, nanoseconds: (ni == 0 ? 0 : tsp[ni].to_i)
    end

    def self.to_json(value : Time::Span, json : JSON::Builder)
      json.string value.to_s
    end
  end
end
