require "./spec_helper"

describe RSS do
  it "works on live PV02 feed" do
    feed = RSS.parse "https://www.pv02comic.com/feed/" # RSS Feed of a nice comic
    feed.items.size.should be > 0
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("PV02")
    feed.description.should eq("A robot named Pivot")
    feed.link.host.should eq("www.pv02comic.com")
    feed.updatePeriod.should eq("hourly")
    feed.updateFrequency.should eq(1)
    # TODO: add some more checks
  end

  it "works on official sample feed" do
    feed = RSS.parse "https://www.rssboard.org/files/sample-rss-2.xml"
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("Liftoff News")
    feed.link.host.should eq("liftoff.msfc.nasa.gov")
    feed.description.should eq("Liftoff to Space Exploration.")
    # TODO: MORE
  end

  it "works on an example feed with every field" do
    server = HTTP::Server.new do |context|
      context.response.puts "
      <?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <rss version=\"2.0\">
        <channel>
          <title>RSS Title &#x26; Name</title>
          <description>This is an example of an RSS feed that uses the &#x3C;rss&#x3E; tag</description>
          <link>http://www.example.com/main.html</link>
          <copyright>2020 Example.com All rights reserved</copyright>
          <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>
          <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
          <ttl>1800</ttl>
          <skipHours>
            <hour>0</hour>
            <hour>15</hour>
            <hour>15</hour>
          </skipHours>
          <skipDays>
            <day>Monday</day>
            <day>friday</day>
          </skipDays>
          <textInput>
            <name>test1-Name:a.b_c</name>
            <description>Test TextInput</description>
            <title>Test</title>
            <link>https://www.example.com/</link>
          </textInput>
          <item>
            <title>Example entry</title>
            <description>Here is some text containing an interesting description.</description>
            <link>http://www.example.com/blog/post/1</link>
            <guid isPermaLink=\"false\">7bd204c6-1655-4c27-aeee-53f933c5395f</guid>
            <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
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
    feed.title.should eq("RSS Title & Name")
    feed.description.should eq("This is an example of an RSS feed that uses the <rss> tag")
    feed.ttl.should_not eq(nil)
    feed.ttl.not_nil!.total_minutes.should eq(1800)
    feed.skipHours.should_not eq(nil)
    feed.skipHours.not_nil!.size.should eq(2)
    feed.skipHours.not_nil!.should eq([0, 15])
    # TODO: check example feed
  end
end
