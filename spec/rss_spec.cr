require "./spec_helper"

describe RSS do
  it "works" do
    feed = RSS.parse "https://www.pv02comic.com/feed/" # RSS Feed of a nice comic
    feed.items.size.should be > 0
    feed.to_s.should eq("version: 2.0")
    feed.title.should eq("PV02")
  end
end
