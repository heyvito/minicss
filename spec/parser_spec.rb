# frozen_string_literal: true

RSpec.describe TinyCSS::CSS::Parser do
  it "parses a small CSS snippet" do
    style = <<~CSS
      body { background-color: #AABBCC; }
    CSS

    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    par.parse_stylesheet
  end

  it "reads a real CSS file" do
    tok = TinyCSS::CSS::Tokenizer.new(File.read(fixture_path("vito_io.css")))
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    par.parse_stylesheet
  end

  it "parses an at-rule" do
    style = <<~CSS
      @media only screen and (min-width: 650px) and (max-height: 1000px) {
        main.home {
          margin-top: 200px;
        }
      }
    CSS

    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    par.consume_at_rule
  end
end
