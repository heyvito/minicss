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

  it "tokenizes escapes 1" do
    style = "\\- red0 -red --red -\\-red\\ blue 0red -0red \x00red _Red .red r\u00EAd r\\\u00EAd \x7F\u0080\u0081"
    tok = described_class.new(style)
    tok.tokenize
    t = tok.tokens
    expect(t.map(&:literal)).to eq [
      "-",
      " ",
      "red0",
      " ",
      "-red",
      " ",
      "--red",
      " ",
      "--red blue",
      " ",
      "0red",
      " ",
      "-0red",
      " ",
      "\uFFFDred",
      " ",
      "_Red",
      " ",
      ".",
      "red",
      " ",
      "rêd",
      " ",
      "rêd",
      " ",
      "\u007F",
      "\u0080\u0081"
    ]
  end

  it "tokenizes escapes 2" do
    style = "rgba0() -rgba() --rgba() -\\-rgba() 0rgba() -0rgba() _rgba() .rgba() rgbâ() \\30rgba() rgba () @rgba() #rgba()"
    tok = described_class.new(style)
    tok.tokenize
    t = tok.tokens
    exp = [
      "rgba0(",
      ")",
      " ",
      "-rgba(",
      ")",
      " ",
      "--rgba(",
      ")",
      " ",
      "--rgba(",
      ")",
      " ",
      "0rgba",
      "(",
      ")",
      " ",
      "-0rgba",
      "(",
      ")",
      " ",
      "_rgba(",
      ")",
      " ",
      ".",
      "rgba(",
      ")",
      " ",
      "rgbâ(",
      ")",
      " ",
      "0rgba(",
      ")",
      " ",
      "rgba",
      " ",
      "(",
      ")",
      " ",
      "@rgba",
      "(",
      ")",
      " ",
      "#rgba",
      "(",
      ")"
    ]
    expect(t.map(&:literal)).to eq exp
  end

  it "tokenizes hashes" do
    style = "#red0 #-Red #--red #-\\-red #0red #-0red #_Red #.red #rêd #êrd #\\.red\\"
    tok = described_class.new(style)
    tok.tokenize
    t = tok.tokens
    expect(t.map(&:literal)).to eq [
      "#red0", " ",
      "#-Red", " ",
      "#--red", " ",
      "#--red", " ",
      "#0red", " ",
      "#-0red", " ",
      "#_Red", " ",
      "#", ".", "red", " ",
      "#rêd", " ",
      "#êrd", " ",
      "#.red\uFFFD"
    ]
  end

  it "tokenizes simple numbers" do
    style = "12 +34 -45 .67 +.89 -.01 2.3 +45.0 -0.67"
    tok = described_class.new(style)
    tok.tokenize
    t = tok.tokens
    expect(t.map(&:literal)).to eq [
      "12", " ",
      "+34", " ",
      "-45", " ",
      ".67", " ",
      "+.89", " ",
      "-.01", " ",
      "2.3", " ",
      "+45.0", " ",
      "-0.67"
    ]
  end
end
