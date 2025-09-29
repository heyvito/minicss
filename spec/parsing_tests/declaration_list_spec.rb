RSpec.describe "css-parsing-tests: declaration_list.json" do
  it "parses \"\"" do
    style = ""
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \";; /**/ ; ;\"" do
    style = ";; /**/ ; ;"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"a:b; c:d 42!important;\\n\"" do
    style = "a:b; c:d 42!important;\n"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"z;a:b\"" do
    style = "z;a:b"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"z:x!;a:b\"" do
    style = "z:x!;a:b"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"a:b; c+:d\"" do
    style = "a:b; c+:d"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"@import 'foo.css'; a:b; @import 'bar.css'\"" do
    style = "@import 'foo.css'; a:b; @import 'bar.css'"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"@media screen { div{;}} a:b;; @media print{div{\"" do
    style = "@media screen { div{;}} a:b;; @media print{div{"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"@ media screen { div{;}} a:b;; @media print{div{\"" do
    style = "@ media screen { div{;}} a:b;; @media print{div{"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

  it "parses \"\"" do
    style = ""
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # declarations
    end
  end

end