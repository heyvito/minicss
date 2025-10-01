class BodyMatcher
  def self.match(node, &) = new(node, &).match

  include RSpecHelpers

  def initialize(node, &block)
    @block = block
    @node = node
    @idx = 0
  end

  def peek = @node[@idx]
  def consume = peek.tap { @idx += 1 }

  def match = instance_exec(&@block)

  def empty!
    expect(@node).to be_empty
  end

  def ident(val)
    expect(peek).to be_a String
    expect(peek).to eq val
    consume
  end

  def string(val)
    expect(peek).to eq val
    consume
  end

  def number(raw, type)
    case peek
    when String
      expect(peek).to eq raw
      consume
    when TinyCSS::AST::Number
      expect(peek.type).to eq type
      expect(peek.value).to eq raw
      consume
    else
      debugger
    end
  end
end
