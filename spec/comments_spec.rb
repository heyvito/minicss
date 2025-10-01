# frozen_string_literal: true

RSpec.describe MiniCSS do
  it "handles comments" do
    style = <<~CSS
      .highlight .c {
        color: #999988;
        font-style: italic;
      } /* Comment */
      .highlight .err {
        color: #a61717;
        background-color: #e3d2d2;
      } /* Error */
    CSS

    tokenizer = MiniCSS::CSS::Tokenizer.new(style)
    tokenizer.tokenize
    parser = MiniCSS::CSS::Parser.new(tokenizer.tokens)
    parser.parse_stylesheet
  end
end
