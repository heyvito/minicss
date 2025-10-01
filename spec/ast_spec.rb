# frozen_string_literal: true

RSpec.describe MiniCSS::AST do
  it "transforms a parsed CSS into AST" do
    style = <<~CSS
      body { background-color: #AABBCC; }
    CSS
    tok = MiniCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = MiniCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    MiniCSS::AST.convert(sheet)
  end

  it "transforms real CSS into AST" do
    tok = MiniCSS::CSS::Tokenizer.new(File.read(fixture_path("vito_io.css")))
    tok.tokenize
    par = MiniCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    MiniCSS::AST.convert(sheet)
  end

  it "parses an at-rule" do
    style = <<~CSS
      @media only screen and (min-width: 650px) and (max-height: 1000px) {
        main.home {
          margin-top: 200px;
        }
      }
    CSS

    tok = MiniCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = MiniCSS::CSS::Parser.new(tok.tokens)
    rule = par.consume_at_rule
    MiniCSS::AST.convert(rule)
  end
end
