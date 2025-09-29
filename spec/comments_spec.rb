# frozen_string_literal: true

RSpec.describe TinyCSS do
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

    tokenizer = TinyCSS::CSS::Tokenizer.new(style)
    tokenizer.tokenize
    parser = TinyCSS::CSS::Parser.new(tokenizer.tokens)
    sheet = parser.parse_stylesheet
  end
end
