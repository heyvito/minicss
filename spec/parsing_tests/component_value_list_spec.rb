RSpec.describe "css-parsing-tests: component_value_list.json" do
  it "parses \"\"" do
    style = ""
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"/*/*///** /* **/*//* \"" do
    style = "/*/*///** /* **/*//* "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"red\"" do
    style = "red"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"  \\t\\t\\r\\n\\nRed \"" do
    style = "  \t\t\r\n\nRed "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"red/* CDC */-->\"" do
    style = "red/* CDC */-->"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"red-->/* Not CDC */\"" do
    style = "red-->/* Not CDC */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"\\\\- red0 -red --red -\\\\-red\\\\ blue 0red -0red \\x00red _Red .red r\\u00EAd r\\\\\\u00EAd \\x7F\\u0080\\u0081\"" do
    style = "\\- red0 -red --red -\\-red\\ blue 0red -0red \x00red _Red .red r\u00EAd r\\\u00EAd \x7F\u0080\u0081"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"\\\\30red \\\\00030 red \\\\30\\r\\nred \\\\0000000red \\\\1100000red \\\\red \\\\r ed \\\\.red \\\\ red \\\\\\nred \\\\376\\\\37 6\\\\000376\\\\0000376\\\\\"" do
    style = "\\30red \\00030 red \\30\r\nred \\0000000red \\1100000red \\red \\r ed \\.red \\ red \\\nred \\376\\37 6\\000376\\0000376\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"rgba0('a' rgba1(a b rgba2(rgba3('b\"" do
    style = "rgba0('a' rgba1(a b rgba2(rgba3('b"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"rgba0() -rgba() --rgba() -\\\\-rgba() 0rgba() -0rgba() _rgba() .rgba() rgb\\u00E2() \\\\30rgba() rgba () @rgba() #rgba()\"" do
    style = "rgba0() -rgba() --rgba() -\\-rgba() 0rgba() -0rgba() _rgba() .rgba() rgb\u00E2() \\30rgba() rgba () @rgba() #rgba()"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"@media0 @-Media @--media @-\\\\-media @0media @-0media @_media @.media @med\\u0130a @\\\\30 media\\\\\"" do
    style = "@media0 @-Media @--media @-\\-media @0media @-0media @_media @.media @med\u0130a @\\30 media\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"#red0 #-Red #--red #-\\\\-red #0red #-0red #_Red #.red #r\\u00EAd #\\u00EArd #\\\\.red\\\\\"" do
    style = "#red0 #-Red #--red #-\\-red #0red #-0red #_Red #.red #r\u00EAd #\u00EArd #\\.red\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"p[example=\\\"\\\\\\nfoo(int x) {\\\\\\n   this.x = x;\\\\\\n}\\\\\\n\\\"]\"" do
    style = "p[example=\"\\\nfoo(int x) {\\\n   this.x = x;\\\n}\\\n\"]"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"'' 'Lorem \\\"\\u00EEpsum\\\"' 'a\\\\\\nb' 'a\\nb 'eof\"" do
    style = "'' 'Lorem \"\u00EEpsum\"' 'a\\\nb' 'a\nb 'eof"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"\\\"\\\" \\\"Lorem '\\u00EEpsum'\\\" \\\"a\\\\\\nb\\\" \\\"a\\nb \\\"eof\"" do
    style = "\"\" \"Lorem '\u00EEpsum'\" \"a\\\nb\" \"a\nb \"eof"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"\\\"Lo\\\\rem \\\\130 ps\\\\u m\\\" '\\\\376\\\\37 6\\\\000376\\\\0000376\\\\\"" do
    style = "\"Lo\\rem \\130 ps\\u m\" '\\376\\37 6\\000376\\0000376\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url( '') url('Lorem \\\"\\u00EEpsum\\\"'\\n) url('a\\\\\\nb' ) url('a\\nb) url('eof\"" do
    style = "url( '') url('Lorem \"\u00EEpsum\"'\n) url('a\\\nb' ) url('a\nb) url('eof"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url(\"" do
    style = "url("
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url( \\t\"" do
    style = "url( \t"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url(\\\"\\\") url(\\\"Lorem '\\u00EEpsum'\\\"\\n) url(\\\"a\\\\\\nb\\\" ) url(\\\"a\\nb) url(\\\"eof\"" do
    style = "url(\"\") url(\"Lorem '\u00EEpsum'\"\n) url(\"a\\\nb\" ) url(\"a\nb) url(\"eof"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url(\\\"Lo\\\\rem \\\\130 ps\\\\u m\\\") url('\\\\376\\\\37 6\\\\000376\\\\0000376\\\\\"" do
    style = "url(\"Lo\\rem \\130 ps\\u m\") url('\\376\\37 6\\000376\\0000376\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"URL(foo) Url(foo) \\u00FBrl(foo) url (foo) url\\\\ (foo) url(\\t 'foo' \"" do
    style = "URL(foo) Url(foo) \u00FBrl(foo) url (foo) url\\ (foo) url(\t 'foo' "
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url('a' b) url('c' d)\"" do
    style = "url('a' b) url('c' d)"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url('a\\nb) url('c\\n\"" do
    style = "url('a\nb) url('c\n"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url() url( \\t) url(\\n Fo\\u00F4\\\\030\\n!\\n) url(\\na\\nb\\n) url(a\\\\ b) url(a(b) url(a\\\\(b) url(a'b) url(a\\\\'b) url(a\\\"b) url(a\\\\\\\"b) url(a\\nb) url(a\\\\\\nb) url(a\\\\a b) url(a\\\\\"" do
    style = "url() url( \t) url(\n Fo\u00F4\\030\n!\n) url(\na\nb\n) url(a\\ b) url(a(b) url(a\\(b) url(a'b) url(a\\'b) url(a\"b) url(a\\\"b) url(a\nb) url(a\\\nb) url(a\\a b) url(a\\"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url(\\x00!\\\#$%&*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~\\u0080\\u0081\\u009E\\u009F\\u00A0\\u00A1\\u00A2\"" do
    style = "url(\x00!\#$%&*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~\u0080\u0081\u009E\u009F\u00A0\u00A1\u00A2"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"url(\\x01) url(\\x02) url(\\x03) url(\\x04) url(\\x05) url(\\x06) url(\\a) url(\\b) url(\\v) url(\\x0E) url(\\x0F) url(\\x10) url(\\x11) url(\\x12) url(\\x13) url(\\x14) url(\\x15) url(\\x16) url(\\x17) url(\\x18) url(\\x19) url(\\x1A) url(\\e) url(\\x1C) url(\\x1D) url(\\x1E) url(\\x1F) url(\\x7F)\"" do
    style = "url(\x01) url(\x02) url(\x03) url(\x04) url(\x05) url(\x06) url(\a) url(\b) url(\v) url(\x0E) url(\x0F) url(\x10) url(\x11) url(\x12) url(\x13) url(\x14) url(\x15) url(\x16) url(\x17) url(\x18) url(\x19) url(\x1A) url(\e) url(\x1C) url(\x1D) url(\x1E) url(\x1F) url(\x7F)"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12 +34 -45 .67 +.89 -.01 2.3 +45.0 -0.67\"" do
    style = "12 +34 -45 .67 +.89 -.01 2.3 +45.0 -0.67"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12e2 +34e+1 -45E-0 .68e+3 +.79e-1 -.01E2 2.3E+1 +45.0e6 -0.67e0\"" do
    style = "12e2 +34e+1 -45E-0 .68e+3 +.79e-1 -.01E2 2.3E+1 +45.0e6 -0.67e0"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"3. /* Decimal point must have following digits */\"" do
    style = "3. /* Decimal point must have following digits */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"3\\\\65-2 /* Scientific notation E can not be escaped */\"" do
    style = "3\\65-2 /* Scientific notation E can not be escaped */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"3e-2.1 /* Integer exponents only */\"" do
    style = "3e-2.1 /* Integer exponents only */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12% +34% -45% .67% +.89% -.01% 2.3% +45.0% -0.67%\"" do
    style = "12% +34% -45% .67% +.89% -.01% 2.3% +45.0% -0.67%"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12e2% +34e+1% -45E-0% .68e+3% +.79e-1% -.01E2% 2.3E+1% +45.0e6% -0.67e0%\"" do
    style = "12e2% +34e+1% -45E-0% .68e+3% +.79e-1% -.01E2% 2.3E+1% +45.0e6% -0.67e0%"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12\\\\% /* Percent sign can not be escaped */\"" do
    style = "12\\% /* Percent sign can not be escaped */"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12px +34px -45px .67px +.89px -.01px 2.3px +45.0px -0.67px\"" do
    style = "12px +34px -45px .67px +.89px -.01px 2.3px +45.0px -0.67px"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12e2px +34e+1px -45E-0px .68e+3px +.79e-1px -.01E2px 2.3E+1px +45.0e6px -0.67e0px\"" do
    style = "12e2px +34e+1px -45E-0px .68e+3px +.79e-1px -.01E2px 2.3E+1px +45.0e6px -0.67e0px"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"12red0 12.0-red 12--red 12-\\\\-red 120red 12-0red 12\\x00red 12_Red 12.red 12r\\u00EAd\"" do
    style = "12red0 12.0-red 12--red 12-\\-red 120red 12-0red 12\x00red 12_Red 12.red 12r\u00EAd"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+1 U+10 U+100 U+1000 U+10000 U+100000 U+1000000\"" do
    style = "u+1 U+10 U+100 U+1000 U+10000 U+100000 U+1000000"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+? u+1? U+10? U+100? U+1000? U+10000? U+100000?\"" do
    style = "u+? u+1? U+10? U+100? U+1000? U+10000? U+100000?"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+?? U+1?? U+10?? U+100?? U+1000?? U+10000??\"" do
    style = "u+?? U+1?? U+10?? U+100?? U+1000?? U+10000??"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+??? U+1??? U+10??? U+100??? U+1000???\"" do
    style = "u+??? U+1??? U+10??? U+100??? U+1000???"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+???? U+1???? U+10???? U+100????\"" do
    style = "u+???? U+1???? U+10???? U+100????"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+????? U+1????? U+10?????\"" do
    style = "u+????? U+1????? U+10?????"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+?????? U+1??????\"" do
    style = "u+?????? U+1??????"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"u+1-2 U+100000-2 U+1000000-2 U+10-200000\"" do
    style = "u+1-2 U+100000-2 U+1000000-2 U+10-200000"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"\\u00F9+12 \\u00DC+12 u +12 U+ 12 U+12 - 20 U+1?2 U+1?-50\"" do
    style = "\u00F9+12 \u00DC+12 u +12 U+ 12 U+12 - 20 U+1?2 U+1?-50"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"~=|=^=$=*=||<!------> |/**/| ~/**/=\"" do
    style = "~=|=^=$=*=||<!------> |/**/| ~/**/="
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"a:not([href^=http\\\\:],  [href ^=\\t'https\\\\:'\\n]) { color: rgba(0%, 100%, 50%); }\"" do
    style = "a:not([href^=http\\:],  [href ^=\t'https\\:'\n]) { color: rgba(0%, 100%, 50%); }"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

  it "parses \"@media print { (foo]{bar) }baz\"" do
    style = "@media print { (foo]{bar) }baz"
    tok = TinyCSS::CSS::Tokenizer.new(style)
    tok.tokenize
    par = TinyCSS::CSS::Parser.new(tok.tokens)
    sheet = par.parse_stylesheet
    r = TinyCSS::AST.convert(sheet)

    match_ast(r) do
      # component_value_list
    end
  end

end