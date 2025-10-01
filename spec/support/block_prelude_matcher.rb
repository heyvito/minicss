class BlockPreludeMatcher
  def self.match(node, &) = new(node, &).match

  include RSpecHelpers

  def initialize(node, &block)
    @block = block
    @node = node
    @idx = 0
    @prelude_idx = 0
  end

  def match = instance_exec(&@block)

  def prelude(&)
    if @node.is_a? TinyCSS::AST::Rule
      LinearMatcher.new(@node.raw_selector).instance_exec(&)
    else
      LinearMatcher.new(@node.prelude).instance_exec(&)
    end
  end

  def body(&)
    ASTMatcher.new(@node.child_rules).instance_exec(&)
  end
end
