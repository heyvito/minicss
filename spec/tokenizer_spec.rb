# frozen_string_literal: true

RSpec.describe TinyCSS::CSS::Tokenizer do
  it "reads a real CSS file" do
    tok = described_class.new(File.read(fixture_path("vito_io.css")))
    tok.tokenize
  end

  it "correctly reads a url token" do
    tok = TinyCSS::CSS::Tokenizer.new("url(https://vito.io)")
    tok.tokenize
    expect(tok.tokens.length).to eq 1
    t = tok.tokens.first
    expect(t.kind).to eq :url
    expect(t.opts[:value]).to eq "https://vito.io"
  end

  it "tokenizes an at-rule" do
    style = <<~CSS
      @font-face {
        font-family: "ITC Garamond Narrow";
        font-weight: 400;
        font-style: normal;
        src: url(/assets/font/itc-garamond-narrow-book.woff2) format("woff2"), url(/assets/font/itc-garamond-narrow-book.woff) format("woff");
      }
    CSS
    tok = described_class.new(style)
    tok.tokenize
    expect(tok.tokens.map(&:kind)).to eq %i[
      at_keyword
      whitespace
      left_curly
      whitespace
      ident
      colon
      whitespace
      string
      semicolon
      whitespace
      ident
      colon
      whitespace
      number
      semicolon
      whitespace
      ident
      colon
      whitespace
      ident
      semicolon
      whitespace
      ident
      colon
      whitespace
      url
      whitespace
      function
      string
      right_parenthesis
      comma
      whitespace
      url
      whitespace
      function
      string
      right_parenthesis
      semicolon
      whitespace
      right_curly
      whitespace
    ]
  end

  it "correctly parses broken dashes" do
    style = "\\-"
    tok = described_class.new(style)
    tok.tokenize
    expect(tok.tokens.first.opts[:value]).to eq "-"
  end
end
