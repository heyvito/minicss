# frozen_string_literal: true

module MiniCSS
  class Serializer
    def self.serialize(root) = new(root).css

    def initialize(root)
      @str = +""
      @root = root
    end

    def serialize(value)
      case value
      when Array
        value.each { serialize(it) }
      when String
        @str << value
      when AST::Rule
        @str << (value.valid_selector? ? Sel.stringify(value.selector) : value.raw_selector) << "{"
        value.decls.each { serialize(it) }
        value.child_rules.each { serialize(it) }
        @str << "}"
      when AST::Decl
        @str << "#{value.name}:"
        value.value.each { serialize(it) }
        @str << (value.important? ? "!important" : "")
        @str << ";"
      when AST::Dimension
        @str << value.sign if value.sign
        @str << (value.type == :integer ? value.value.to_i : value.value.to_f).to_s
        @str << value.unit
      when AST::Percentage
        @str << value.sign if value.sign
        @str << (value.type == :integer ? value.value.to_i : value.value.to_f).to_s
        @str << "%"
      when AST::Number
        @str << value.sign if value.sign
        @str << (value.type == :integer ? value.value.to_i : value.value.to_f).to_s
      when AST::AtRule
        @str << "@" << value.name
        if value.prelude && !value.prelude.nil? && !value.prelude.empty?
          @str << " "
          value.prelude.each { serialize(it) }
        end

        if value.child_rules.empty?
          @str << ";"
        else
          @str << "{"
          value.child_rules.each { serialize(it) }
          @str << "}"
        end
      when AST::URL
        @str << "url(" << value.value << ")"
      when AST::Function
        @str << value.name << "("
        value.value.each { serialize(it) }
        @str << ")"
      when AST::Block
        @str << value.left_token
        value.value.each { serialize(it) }
        @str << value.right_token
      when AST::StringToken
        @str << value.quoting << (value.value || "") << value.quoting
      else
        raise "Unexpected element in serialization pipeline: #{value.class} #{value.inspect}"
      end
    end

    def css
      serialize(@root)
      @str
    end
  end
end
