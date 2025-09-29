RSpec.describe "css-parsing-tests: one_rule.json" do
  it "parses \"\"" do
    style = ""
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"foo\"" do
    style = "foo"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"foo 4\"" do
    style = "foo 4"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"@foo\"" do
    style = "@foo"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"@foo bar; \\t/* comment */\"" do
    style = "@foo bar; \t/* comment */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \" /**/ @foo bar{[(4\"" do
    style = " /**/ @foo bar{[(4"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"@foo { bar\"" do
    style = "@foo { bar"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"@foo [ bar\"" do
    style = "@foo [ bar"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \" /**/ div > p { color: #aaa;  } /**/ \"" do
    style = " /**/ div > p { color: #aaa;  } /**/ "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \" /**/ { color: #aaa  \"" do
    style = " /**/ { color: #aaa  "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \" /* CDO/CDC are not special */ <!-- --> {\"" do
    style = " /* CDO/CDC are not special */ <!-- --> {"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"div { color: #aaa; } p{}\"" do
    style = "div { color: #aaa; } p{}"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"div {} -->\"" do
    style = "div {} -->"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

  it "parses \"{}a\"" do
    style = "{}a"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # rule
    end
  end

end