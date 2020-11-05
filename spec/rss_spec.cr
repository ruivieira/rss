require "./spec_helper"

describe RSS do
  it "works on live PV02 feed" do
    feed = RSS.parse "https://www.pv02comic.com/feed/", 0 # RSS Feed of a nice comic
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("PV02")
    feed.description.should eq("A robot named Pivot")
    feed.link.should eq(URI.parse "https://www.pv02comic.com")
    feed.updatePeriod.should eq("hourly")
    feed.updateFrequency.should eq(1)
    feed.ttl.should eq(Time::Span.new minutes: 60)
    feed.image.should eq(RSS::Image.new URI.parse("https://www.pv02comic.com/wp-content/uploads/2017/07/cropped-nui-icon-1-32x32.png"), "PV02", URI.parse("https://www.pv02comic.com"), 32_u32, 32_u32)
    feed.items.size.should be > 0
  end

  it "follows redirects" do
    feed = RSS.parse "https://pv02comic.com/feed/"
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("PV02")
    feed.description.should eq("A robot named Pivot")
  end

  it "works on official sample feed" do
    feed = RSS.parse "https://www.rssboard.org/files/sample-rss-2.xml"
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("Liftoff News")
    feed.link.should eq(URI.parse "http://liftoff.msfc.nasa.gov/")
    feed.description.should eq("Liftoff to Space Exploration.")
    feed.language.should eq("en-us")
    feed.pubDate.should eq(Time::Format::HTTP_DATE.parse "Tue, 10 Jun 2003 04:00:00 GMT")
    feed.lastBuildDate.should eq(Time::Format::HTTP_DATE.parse "Tue, 10 Jun 2003 09:41:01 GMT")
    feed.docs.should eq(URI.parse "http://blogs.law.harvard.edu/tech/rss")
    feed.generator.should eq("Weblog Editor 2.0")
    feed.managingEditor.should eq("editor@example.com")
    feed.webMaster.should eq("webmaster@example.com")
    feed.items.size.should eq(4)
    feed.items[0].title.should eq("Star City")
    feed.items[0].link.should eq(URI.parse "http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp")
    feed.items[0].description.should eq("How do Americans get ready to work with Russians aboard the International Space Station? They take a crash course in culture, language and protocol at Russia's <a href=\"http://howe.iki.rssi.ru/GCTC/gctc_e.htm\">Star City</a>.")
    feed.items[0].pubDate.should eq(Time::Format::HTTP_DATE.parse "Tue, 03 Jun 2003 09:39:21 GMT")
    feed.items[0].guid.should eq(RSS::GUID.new "http://liftoff.msfc.nasa.gov/2003/06/03.html#item573")
    feed.items[1].title.should be_nil
    feed.items[1].description.should eq("Sky watchers in Europe, Asia, and parts of Alaska and Canada will experience a <a href=\"http://science.nasa.gov/headlines/y2003/30may_solareclipse.htm\">partial eclipse of the Sun</a> on Saturday, May 31st.")
    feed.items[1].pubDate.should eq(Time::Format::HTTP_DATE.parse "Fri, 30 May 2003 11:06:42 GMT")
    feed.items[1].guid.should eq(RSS::GUID.new "http://liftoff.msfc.nasa.gov/2003/05/30.html#item572")
  end

  it "works on an example feed with every field" do
    server = HTTP::Server.new do |context|
      context.response.puts "
      <?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <rss version=\"2.0\">
        <channel>
          <title>RSS Example Title &#x26; Name</title>
          <link>http://www.example.com/main.html</link>
          <description>This is an example of an RSS feed that uses the &#x3C;rss&#x3E; tag</description>
          <language>en-US</language>
          <copyright>2020 Example.com All rights reserved</copyright>
          <managingEditor>editor@example.com</managingEditor>
          <webMaster>webmaster@example.com</webMaster>
          <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
          <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000</lastBuildDate>
          <category domain=\"example\">Example Category 1</category>
          <category>Example Category 2</category>
          <generator>Keyboard&#x26;Hand generator v1</generator>
          <docs>http://www.example.com/docs</docs>
          <cloud domain=\"www.example.com\" port=\"8080\" path=\"/rpc\" protocol=\"xml-rpc\" registerProcedure=\"myCloud.rssPleaseNotify\" />
          <ttl>1800</ttl>
          <image>
            <url>http://www.example.com/images/image.png</url>
            <title>Example Image</title>
            <link>http://www.example.com/</link>
            <width>32</width>
            <height>32</height
            <description>Example image description</description>
          </image>
          <rating>Rating goes here</rating>
          <textInput>
            <title>Example Input</title>
            <description>Example description of input</description>
            <name>3xample-test.In:123_0</name>
            <link>https://www.example.com/</link>
          </textInput>
          <skipHours>
            <hour>0</hour>
            <hour>15</hour>
            <hour>15</hour>
          </skipHours>
          <skipDays>
            <day>Monday</day>
            <day>Monday</day>
            <day>Friday</day>
            <day>Sunday</day>
          </skipDays>
          <item>
            <title>Example entry</title>
            <link>http://www.example.com/blog/post/1</link>
            <description>Here is some text containing an interesting description.</description>
            <author>Example Author</author>
            <category domain=\"example\">Example Category 3</category>
            <category>Example Category 4</category>
            <comments>http://wwww.example.com/blog/post/1/comments</comments>
            <enclosure length=\"123\" type=\"audio/mpeg\" url=\"http://www.example.com/bloc/post/1/post1.mp3\" />
            <guid isPermaLink=\"false\">7bd204c6-1655-4c27-aeee-53f933c5395f</guid>
            <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
            <source url=\"http://www.example.com/blog2/rss\">Example Second Blog</source
          </item>
          <item>
            <title>Minimal Example entry</title>
          </item>
        </channel>
      </rss>
      "
    end
    spawn do
      server.bind_tcp "127.0.0.1", 8295
      server.listen
    end
    sleep 0.001
    feed = RSS.parse "http://127.0.0.1:8295/"
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("RSS Example Title & Name")
    feed.link.should eq(URI.parse "http://www.example.com/main.html")
    feed.description.should eq("This is an example of an RSS feed that uses the <rss> tag")
    feed.language.should eq("en-US")
    feed.copyright.should eq("2020 Example.com All rights reserved")
    feed.managingEditor.should eq("editor@example.com")
    feed.webMaster.should eq("webmaster@example.com")
    feed.pubDate.should eq(Time::Format::HTTP_DATE.parse "Sun, 06 Sep 2009 16:20:00 +0000")
    feed.lastBuildDate.should eq(Time::Format::HTTP_DATE.parse "Mon, 06 Sep 2010 00:01:00 +0000")
    feed.categories.should eq([RSS::Category.new("Example Category 1", "example"), RSS::Category.new("Example Category 2")])
    feed.generator.should eq("Keyboard&Hand generator v1")
    feed.docs.should eq(URI.parse "http://www.example.com/docs")
    feed.cloud.should eq(RSS::Cloud.new "www.example.com", 8080_u16, "/rpc", "myCloud.rssPleaseNotify", "xml-rpc")
    feed.ttl.should eq(Time::Span.new minutes: 1800)
    feed.image.should eq(RSS::Image.new URI.parse("http://www.example.com/images/image.png"), "Example Image", URI.parse("http://www.example.com/"), 32_u32, 32_u32, "Example image description")
    feed.rating.should eq("Rating goes here")
    feed.textInput.should eq(RSS::TextInput.new "Example Input", "Example description of input", "3xample-test.In:123_0", URI.parse("https://www.example.com/"))
    feed.skipHours.should eq([0, 15])
    feed.skipDays.should eq([Time::DayOfWeek::Monday, Time::DayOfWeek::Friday, Time::DayOfWeek::Sunday])
    feed.items.size.should eq(2)
    feed.items[0].title.should eq("Example entry")
    feed.items[0].link.should eq(URI.parse "http://www.example.com/blog/post/1")
    feed.items[0].description.should eq("Here is some text containing an interesting description.")
    feed.items[0].author.should eq("Example Author")
    feed.items[0].categories.should eq([RSS::Category.new("Example Category 3", "example"), RSS::Category.new("Example Category 4")])
    feed.items[0].comments.should eq(URI.parse "http://wwww.example.com/blog/post/1/comments")
    feed.items[0].enclosure.should eq(RSS::Enclosure.new URI.parse("http://www.example.com/bloc/post/1/post1.mp3"), 123_u64, "audio/mpeg")
    feed.items[0].guid.should eq(RSS::GUID.new "7bd204c6-1655-4c27-aeee-53f933c5395f", false)
    feed.items[0].pubDate.should eq(Time::Format::HTTP_DATE.parse "Sun, 06 Sep 2009 16:20:00 +0000")
    feed.items[0].source.should eq(RSS::Source.new "Example Second Blog", URI.parse("http://www.example.com/blog2/rss"))
    feed.items[1].title.should eq("Minimal Example entry")
    feed.items[1].description.should be_nil
    feed.items[1].link.should be_nil
  end

  it "converts to json" do
    feed = RSS.parse "https://www.pv02comic.com/feed/"
    feed.to_json.should_not be_nil
    feed = RSS.parse "http://127.0.0.1:8295"
    json = feed.to_json
    json.should_not be_nil
    RSS::Feed.from_json(json).should_not be_nil
  end
end
