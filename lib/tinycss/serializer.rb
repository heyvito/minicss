# frozen_string_literal: true

module TinyCSS
  module Serializer
    module_function

    def serialize(value)
      case value
      when Array
        value.map { serialize(it) }.flatten.compact.join
      when String
        value
      when AST::Rule
        [
          Sel.stringify(value.selector), "{",
          value.decls.map { serialize(it) },
          value.child_rules.map { serialize(it) },
          "}"
        ].flatten.compact.join
      when AST::Decl
        [
          "#{value.name}:",
          value.value.map { serialize(it) },
          value.important? ? "!important" : nil,
          ";"
        ].flatten.compact.join
      when AST::Number
        [
          value.sign,
          (value.type == :integer ? value.value.to_i : value.value.to_f).to_s
        ].compact.join
      when AST::AtRule
        [
          "@",
          value.name,
          value.prelude && !value.prelude.nil? && !value.prelude.empty? ? " #{value.prelude.map { serialize(it) }.flatten.compact.join}" : nil,
          "{",
          value.child_rules.map { serialize(it) }
        ].flatten.compact.join
      when AST::URL
        "url(#{value.value})"
      when AST::Function
        [value.name, "(",
         value.value.map { serialize(it) },
         ")"].join
      when AST::Block
        [
          value.left_token,
          value.value.map { serialize(it) },
          value.right_token
        ].flatten.compact.join
      when AST::StringToken
        [value.quoting, value.value, value.quoting].flatten.compact.join
      else
        raise "Unexpected element in serialization pipeline: #{value.class} #{value.inspect}"
      end
    end
  end
end
