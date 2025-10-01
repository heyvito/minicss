class LinearMatcher
  include RSpecHelpers

  def initialize(objs)
    @objs = objs
    @idx = 0
  end

  def peek = @objs[@idx]
  def consume = peek.tap { @idx += 1 }

  def string(val)
    if @objs.is_a? String
      expect(@objs[@idx...]).to start_with val
      @idx += val.length
    else
      expect(peek).to eq val
      consume
    end
  end

  def ident(val) = string(val)

  def block(brace, &)
    ASTMatcher.new([peek]).block(brace, &)
    consume
  end

  def empty!
    expect(@objs).to be_empty
  end
end
