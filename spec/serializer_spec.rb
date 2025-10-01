# frozen_string_literal: true

RSpec.describe MiniCSS::Serializer do
  it "serializes a declaration" do
    style = "foo { a:b }"
    ast = MiniCSS.parse(style)
    dump = MiniCSS.serialize(ast)
    expect(dump).to eq "foo{a:b;}"
  end

  it "serialize multiple declarations" do
    style = "foo { a:b } bar { c:d }"
    ast = MiniCSS.parse(style)
    dump = MiniCSS.serialize(ast)
    expect(dump).to eq "foo{a:b;}bar{c:d;}"
  end

  it "reserialize a CSS file" do
    ast = File.open(fixture_path("vito_io.css")) { MiniCSS.parse(it) }
    MiniCSS.serialize(ast)
  end

  it "deserializes and reserializes strings with whitespaces" do
    style = "div { content: \" \"; }"
    ast = MiniCSS.parse(style)
    dump = MiniCSS.serialize(ast)
    expect(dump).to eq "div{content:\" \";}"
  end
end
