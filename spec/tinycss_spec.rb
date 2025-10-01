# frozen_string_literal: true

RSpec.describe TinyCSS do
  it "has a version number" do
    expect(TinyCSS::VERSION).not_to be nil
  end

  it "tokenizes a stylesheet" do
    tokens = File.open(fixture_path("vito_io.css")) do |f|
      TinyCSS.tokenize(f)
    end
    expect(tokens).not_to be_nil
  end

  it "parses a stylesheet" do
    sheet = File.open(fixture_path("vito_io.css")) do |f|
      TinyCSS.parse(f)
    end
    expect(sheet).not_to be_nil
  end
end
