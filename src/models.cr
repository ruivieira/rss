module RSS
  extend self

  class ParserException < Exception
  end

  class Item
    include JSON::Serializable

    property title : String?
    property link : URI?
    property description : String?
    property author : String?
    property category : Category?
    property comments : URI?
    property enclosure : Enclosure?
    property guid : GUID?
    property pubDate : Time?
    property source : Source?

    def initialize(@title = nil, @link = nil, @pubDate = nil, @comments = nil, @description = nil, @guid = nil, @author = nil, @category = nil, @enclosure = nil, @source = nil)
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
      GUID.new node.content, node["isPermaLink"]?.nil? ? false : node["isPermaLink"] == "true"
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
      Category.new node.content, node["domain"]?.nil? ? "" : node["domain"]
    end
  end

  struct Enclosure
    include JSON::Serializable

    property url : URI
    property length : UInt64
    property type : String

    def initialize(@url, @length, @type)
    end

    def to_s
      ""
    end

    def self.from_node(node : XML::Node)
      begin
        Enclosure.new URI.parse(node["url"]), node["length"].to_u64, node["type"]
      rescue
        nil
      end
    end
  end

  struct Source
    include JSON::Serializable

    property content : String
    property url : URI

    def initialize(@content, @url)
    end

    def to_s
      @content
    end

    def self.from_node(node : XML::Node)
      begin
        Source.new node.content, node["url"]?.nil? ? URI.new : URI.parse(node["url"])
      rescue
        nil
      end
    end
  end
end
