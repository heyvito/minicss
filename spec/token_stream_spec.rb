RSpec.describe MiniCSS::CSS::TokenStream do
  subject do
    described_class.new([
      MiniCSS::CSS::Token.new(:string, nil, nil, literal: "str0"),
      MiniCSS::CSS::Token.new(:whitespace, nil, nil),
      MiniCSS::CSS::Token.new(:whitespace, nil, nil),
      MiniCSS::CSS::Token.new(:string, nil, nil, literal: "str1"),
      MiniCSS::CSS::Token.new(:whitespace, nil, nil),
      MiniCSS::CSS::Token.new(:string, nil, nil, literal: "str2"),
      MiniCSS::CSS::Token.new(:string, nil, nil, literal: "str3"),
      MiniCSS::CSS::Token.new(:string, nil, nil, literal: "str4")
    ])
  end

  it "peeks an object" do
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str0"
  end

  it "discards whitespace" do
    subject.consume # consume str0
    subject.discard_whitespace
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str1"
  end

  it "marks and restores" do
    subject.mark
    subject.consume # consume str0
    subject.discard_whitespace
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str1"
    subject.restore
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str0"
  end

  it "marks and pops" do
    subject.mark
    subject.consume # consume str0
    subject.discard_whitespace
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str1"
    subject.pop
    expect(subject.peek.kind).to eq :string
    expect(subject.peek.literal).to eq "str1"
  end
end
