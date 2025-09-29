RSpec.describe "css-parsing-tests: one_component_value.json" do
  it "parses \"\"" do
    style = ""
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \" \"" do
    style = " "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \"/**/\"" do
    style = "/**/"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \"  /**/\\t/* a */\\n\\n\"" do
    style = "  /**/\t/* a */\n\n"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \".\"" do
    style = "."
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \"a\"" do
    style = "a"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \"/**/ 4px\"" do
    style = "/**/ 4px"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \"rgba(100%, 0%, 50%, .5)\"" do
    style = "rgba(100%, 0%, 50%, .5)"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \" /**/ { foo: bar; @baz [)\"" do
    style = " /**/ { foo: bar; @baz [)"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

  it "parses \".foo\"" do
    style = ".foo"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value
    end
  end

end