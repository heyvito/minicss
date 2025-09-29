RSpec.describe "css-parsing-tests: blocks_contents.json" do
  it "parses \";; /**/ ; ;\"" do
    style = ";; /**/ ; ;"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      empty!
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
      decl("a", important: false) do
        ident "b"
      end
      decl("c", important: true) do
        ident "d"
        string " "
        number "42", :integer
      end
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
      # TODO: error
      decl("a", important: false) do
        ident "b"
      end
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
      decl("z", important: false) do
        ident "x"
        string "!"
      end
      decl("a", important: false) do
        ident "b"
      end
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
      decl("a", important: false) do
        ident "b"
      end
      # TODO: error
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
      at_rule("import") do
        prelude do
          string " "
          string "foo.css"
        end
      end
      decl("a", important: false) do
        ident "b"
      end
      at_rule("import") do
        prelude do
          string " "
          string "bar.css"
        end
      end
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
      at_rule("media") do
        prelude do
          string " "
          ident "screen"
          string " "
        end
      end
      decl("a", important: false) do
        ident "b"
      end
      at_rule("media") do
        prelude do
          string " "
          ident "print"
        end
      end
    end
  end

  it "parses \"@ media screen { div{;}} a:b;; @media print{div{\"" do
    style = "@ media screen { div{;}} a:b;; @media print{div{"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    debugger

    match_ast(r) do
      q_rule do
        prelude do
          string "@"
          string " "
          ident "media"
          string " "
          ident "screen"
          string " "
        end
        body do
          string " "
          ident "div"
          block("{") do
          end
        end
      end
      decl("a", important: false) do
        ident "b"
      end
      at_rule("media") do
        prelude do
          string " "
          ident "print"
        end
      end
    end
  end

  it "parses \"z:x;a b{c:d;;e:f}\"" do
    style = "z:x;a b{c:d;;e:f}"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      decl("z", important: false) do
        ident "x"
      end
      q_rule do
        prelude do
          ident "a"
          string " "
          ident "b"
        end
        body do
          ident "c"
          string ":"
          ident "d"
          ident "e"
          string ":"
          ident "f"
        end
      end
    end
  end

  it "parses \"a {c:1}\"" do
    style = "a {c:1}"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      q_rule do
        prelude do
          ident "a"
          string " "
        end
        body do
          ident "c"
          string ":"
          number "1", :integer
        end
      end
    end
  end

  it "parses \"a:hover {c:1}\"" do
    style = "a:hover {c:1}"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      q_rule do
        prelude do
          ident "a"
          string ":"
          ident "hover"
          string " "
        end
        body do
          ident "c"
          string ":"
          number "1", :integer
        end
      end
    end
  end

  it "parses \"z:x;a b{c:d}e:f\"" do
    style = "z:x;a b{c:d}e:f"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      decl("z", important: false) do
        ident "x"
      end
      q_rule do
        prelude do
          ident "a"
          string " "
          ident "b"
        end
        body do
          ident "c"
          string ":"
          ident "d"
        end
      end
      decl("e", important: false) do
        ident "f"
      end
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
      empty!
    end
  end

end
