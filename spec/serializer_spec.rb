# frozen_string_literal: true

RSpec.describe TinyCSS::Serializer do
  it "serializes a declaration" do
    style = "foo { a:b }"
    ast = TinyCSS.parse(style)
    dump = TinyCSS.serialize(ast)
    expect(dump).to eq "foo{a:b;}"
  end

  it "serialize multiple declarations" do
    style = "foo { a:b } bar { c:d }"
    ast = TinyCSS.parse(style)
    dump = TinyCSS.serialize(ast)
    expect(dump).to eq "foo{a:b;}bar{c:d;}"
  end

  it "reserialize a CSS file" do
    ast = File.open(fixture_path("vito_io.css")) { TinyCSS.parse(it) }
    TinyCSS.serialize(ast)
  end

  it "deserializes and reserializes strings with whitespaces" do
    style = "div { content: \" \"; }"
    ast = TinyCSS.parse(style)
    dump = TinyCSS.serialize(ast)
    expect(dump).to eq "div{content:\" \";}"
  end
end
