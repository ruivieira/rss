require "./spec_helper"

describe RSS do
  it "works on live PV02 feed" do
    feed = RSS.parse "https://www.pv02comic.com/feed/" # RSS Feed of a nice comic
    feed.items.size.should be > 0
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("PV02")
  end

  it "works on example feed from wikipedia" do
    server = HTTP::Server.new do |context|
      context.response.puts "
      <?xml version=\"1.0\" encoding=\"UTF-8\" ?>
      <rss version=\"2.0\">
        <channel>
          <title>RSS Title</title>
          <description>This is an example of an RSS feed</description>
          <link>http://www.example.com/main.html</link>
          <copyright>2020 Example.com All rights reserved</copyright>
          <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>
          <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
          <ttl>1800</ttl>
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
    sleep 0.1
    feed = RSS.parse "http://127.0.0.1:8295/"
  end
end
