# frozen_string_literal: true

module TinyCSS
  module CSS
    class Parser
      using StringRefinements

      attr_reader :stream

      def initialize(tokens)
        @stream = TokenStream.new(tokens)
        @tokens = tokens
      end

      # Entrypoints

      def parse_stylesheet
        AST::Stylesheet.new(rules: consume_stylesheet_contents)
      end

      def parse_stylesheet_contents
        consume_stylesheet_contents
      end

      def parse_block_contents
        consume_block_contents
      end

      def parse_rule
        stream.discard_whitespace
        result = if stream.peek.kind == :at_keyword
          consume_at_rule
        else
          consume_qualified_rule
        end
        stream.discard_whitespace
        # If the next token from input is an <EOF-token>, return rule. Otherwise, return a syntax error.
        result
      end

      def parse_declaration
        stream.discard_whitespace
        consume_declaration
      end

      def parse_component_value
        stream.discard_whitespace
        # If input is empty, return a syntax error.
        value = consume_component_value
        stream.discard_whitespace
        # If input is empty, return value. Otherwise, return a syntax error.
        value
      end

      def parse_component_value_list
        consume_component_value_list
      end

      def parse_component_value_comma_list
        groups = []
        until stream.empty?
          groups << consume_component_value_list(stop: :comma)
          stream.discard
        end
        groups
      end

      # Helpers

      def assert_next_token(kind)
        stream.peek.kind == kind
      end

      # Parsers

      def consume_stylesheet_contents
        rules = []
        loop do
          case stream.peek.kind
          when :whitespace, :cdo, :cdc
            stream.discard

          when :eof
            return rules

          when :at_keyword
            rule = consume_at_rule
            rules << rule if rule

          else
            rule = consume_qualified_rule
            rules << rule if rule
          end
        end
      end

      def consume_at_rule(nested: false)
        return unless assert_next_token(:at_keyword)

        rule = AST::AtRule.new(name: stream.consume)
        loop do
          case stream.peek.kind
          when :semicolon, :eof
            stream.discard
            # TODO: If rule is valid in the current context, return it; otherwise return nothing.
            return rule

          when :right_curly
            if nested
              # TODO: If rule is valid in the current context, return it. Otherwise, return nothing.
              return rule
            end

            rule.prelude << consume

          when :left_curly
            consume_block.each { rule.child_rules << it }
            return rule

          else
            rule.prelude << consume_component_value
          end
        end
      end

      def consume_qualified_rule(stop: nil, nested: false)
        rule = AST::QualifiedRule.new

        loop do
          case stream.peek.kind
          when :eof, stop
            return nil

          when :right_curly
            return nil if nested

            rule.prelude << consume

          when :left_curly
            non_ws = rule.prelude.reject { it.kind == :whitespace }
            first, second = non_ws.first(2)

            if first&.kind == :ident && first.literal.start_with?("--") && second&.kind == :colon
              nested ? consume_bad_declaration : consume_block
              return nil
            end

            child_rules = consume_block

            rule.decls = child_rules.shift if child_rules&.first.is_a?(AST::DeclarationList)

            # Replace declaration lists with nested declaration rules
            rule.child_rules = child_rules.map do |item|
              item.is_a?(AST::DeclarationList) ? AST::NestedDeclarationRules.new(child: item) : item
            end

            # TODO: If rule is valid in the current context, return it; otherwise
            # return an invalid rule error.
            return rule

          else
            rule.prelude << consume_component_value
          end
        end
      end

      def consume_block
        return unless assert_next_token(:left_curly)

        stream.discard
        rules = consume_block_contents
        stream.discard
        rules
      end

      def consume_block_contents
        rules = []
        decls = AST::DeclarationList.new

        loop do
          case stream.peek.kind
          when :whitespace, :semicolon
            stream.discard
          when :eof, :right_curly
            rules << decls unless decls.empty?
            return rules
          when :at_keyword
            unless decls.empty?
              rules << decls
              decls = AST::DeclarationList.new
            end
            at = consume_at_rule(nested: true)
            rules << at if at.is_a? AST::AtRule
          else
            stream.mark
            decl = consume_declaration(nested: true)
            if decl.is_a? AST::Declaration
              decls << decl
              stream.pop
              next
            end

            stream.restore
            rule = consume_qualified_rule(nested: true, stop: :semicolon)
            if rule.is_a? InvalidRuleError
              unless decls.empty?
                rules << decls
                decls = AST::DeclarationList.new
              end
            elsif rule.is_a? AST::QualifiedRule
              unless decls.empty?
                rules << decls
                decls = AST::DeclarationList.new
              end
              rules << rule
            end
          end
        end
      end

      def consume_declaration(nested: false)
        decl = AST::Declaration.new
        if stream.peek.kind == :ident
          decl.name = stream.consume
        else
          consume_bad_declaration(nested:)
          return nil
        end

        stream.discard_whitespace

        if stream.peek.kind == :colon
          stream.discard
        else
          consume_bad_declaration(nested:)
          return nil
        end

        stream.discard_whitespace

        decl.value = consume_component_value_list(nested:, stop: :semicolon)

        l1, l2 = decl.value.reject { it.kind == :whitespace }.last(2)
        if l1 && l2 && l1.kind == :delim && l1.literal == "!" && l2.kind == :ident && l2.literal.downcase == "important"
          decl.value.delete(l1)
          decl.value.delete(l2)
          decl.important = true
        end
        decl.value.pop while decl.value.last&.kind == :whitespace
        decl.original_text = decl.value.map(&:literal).join if decl.name.literal.start_with?("--")

        # TODO: Otherwise, if decl’s value contains a top-level simple block
        # with an associated token of <{-token>, and also contains any other
        # non-<whitespace-token> value, return nothing. (That is, a top-level
        # {}-block is only allowed as the entire value of a non-custom property.)

        decl
      end

      def consume_bad_declaration(nested:)
        loop do
          case stream.peek.kind
          when :eof, :semicolon
            stream.discard
            return nil
          when :right_curly
            return if nested

            stream.discard
          else
            consume_component_value
          end
        end
      end

      def consume_component_value_list(stop: nil, nested: false)
        values = []
        loop do
          case stream.peek.kind
          when :eof, stop
            return values

          when :right_curly
            return values if nested

            values << stream.consume

          else
            values << consume_component_value
          end
        end
      end

      def consume_component_value
        case stream.peek.kind
        when :left_curly, :left_square_bracket, :left_parenthesis
          consume_simple_block
        when :function
          consume_function
        else
          stream.consume
        end
      end

      def consume_simple_block
        return unless assert_next_token(:left_curly) || assert_next_token(:left_square_bracket) || assert_next_token(:left_parenthesis)

        block = AST::SimpleBlock.new(associated_token: stream.consume.kind)
        ending_token = case block.associated_token
        when :left_curly then :right_curly
        when :left_parenthesis then :right_parenthesis
        when :left_square_bracket then :right_square_bracket
        end

        loop do
          case stream.peek.kind
          when :eof, ending_token
            stream.discard
            return block
          else
            block.value << consume_component_value
          end
        end
      end

      def consume_function
        return unless assert_next_token(:function)

        func = AST::Function.new(name: stream.consume)

        loop do
          case stream.peek.kind
          when :eof, :right_parenthesis
            stream.discard
            return func
          else
            func.value << consume_component_value
          end
        end
      end
    end
  end
end
