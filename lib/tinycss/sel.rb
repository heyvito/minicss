# frozen_string_literal: true

module TinyCSS
  module Sel
    module_function

    PLACEHOLDER_CHAR = "¶"
    ESCAPE_SENTINEL = "\uE000"
    STRING_SENTINEL = "\uE001"

    TOKENS = {
      "attribute" => /\[\s*(?:(?<namespace>\*|[-\w\p{^ASCII}]*)\|)?(?<name>[-\w\p{^ASCII}]+)\s*(?:(?<operator>\W?=)\s*(?<value>.+?)\s*(\s(?<caseSensitive>[iIsS]))?\s*)?\]/u,
      "id" => /#(?<name>[-\w\p{^ASCII}]+)/u,
      "class" => /\.(?<name>[-\w\p{^ASCII}]+)/u,
      "comma" => /\s*,\s*/u,
      "combinator" => /\s*[\s>+~]\s*/u,
      "pseudo-element" => /::(?<name>[-\w\p{^ASCII}]+)(?:\((?<argument>¶*)\))?/u,
      "pseudo-class" => /:(?<name>[-\w\p{^ASCII}]+)(?:\((?<argument>¶*)\))?/u,
      "universal" => /(?:(?<namespace>\*|[-\w\p{^ASCII}]*)\|)?\*/u,
      "type" => /(?:(?<namespace>\*|[-\w\p{^ASCII}]*)\|)?(?<name>[-\w\p{^ASCII}]+)/u
    }.freeze

    ARGUMENT_PATTERNS = {
      "pseudo-element" => Regexp.new(
        TOKENS["pseudo-element"].source.sub("(?<argument>¶*)", "(?<argument>.*)"),
        TOKENS["pseudo-element"].options
      ),
      "pseudo-class" => Regexp.new(
        TOKENS["pseudo-class"].source.sub("(?<argument>¶*)", "(?<argument>.*)"),
        TOKENS["pseudo-class"].options
      )
    }.freeze

    TRIM_TOKENS = Set.new(%w[combinator comma]).freeze

    RECURSIVE_PSEUDO_CLASSES = Set.new(
      %w[not is where has matches -moz-any -webkit-any nth-child nth-last-child]
    ).freeze

    NTH_CHILD_REGEXP = /(?<index>[\dn+-]+)\s+of\s+(?<subtree>.+)/u

    RECURSIVE_PSEUDO_CLASSES_ARGS = {
      "nth-child" => NTH_CHILD_REGEXP,
      "nth-last-child" => NTH_CHILD_REGEXP
    }.freeze

    STRING_PATTERN = /(['"])([^\\\n]*?)\1/u
    ESCAPE_PATTERN = /\\./u

    def get_argument_pattern_by_type(type)
      ARGUMENT_PATTERNS[type] || TOKENS[type]
    end

    def gobble_parens(text, offset)
      nesting = 0
      result = +""
      while offset < text.length
        char = text[offset]
        case char
        when "("
          nesting += 1
        when ")"
          nesting -= 1
        end
        result << char
        offset += 1
        return result if nesting.zero?
      end
      result
    end

    def tokenize_by(text, grammar = TOKENS)
      return [] if text.nil? || text.empty?

      tokens = [text.dup]

      grammar.each do |type, pattern|
        i = 0
        while i < tokens.length
          token = tokens[i]
          unless token.is_a?(String)
            i += 1
            next
          end

          match = pattern.match(token)
          if match.nil?
            i += 1
            next
          end

          content = match[0]
          start_index = match.begin(0)
          before = token[0...start_index]
          after = token[(start_index + content.length)..]
          parts = []

          parts << before if before && !before.empty?

          named = match.named_captures.transform_keys(&:to_sym)
          parts << named.merge(type: type, content: content)

          parts << after if after && !after.empty?

          tokens.slice!(i)
          tokens.insert(i, *parts)
        end
      end

      offset = 0
      tokens.each do |token|
        case token
        when String
          raise ArgumentError,
                "Unexpected sequence #{token} found at index #{offset}"
        when Hash
          offset += token[:content].length
          token[:pos] = [offset - token[:content].length, offset]
          if TRIM_TOKENS.include?(token[:type])
            trimmed = token[:content].strip
            token[:content] = trimmed.empty? ? " " : trimmed
          end
        end
      end

      tokens
    end

    def tokenize(selector, grammar = TOKENS)
      selector = selector.to_s.strip
      return [] if selector.empty?

      replacements = []

      selector = selector.gsub(ESCAPE_PATTERN) do |value|
        offset = Regexp.last_match.begin(0)
        replacements << { value: value, offset: offset }
        ESCAPE_SENTINEL * value.length
      end

      selector = selector.gsub(STRING_PATTERN) do |value|
        match = Regexp.last_match
        quote = match[1]
        content = match[2] || ""
        offset = match.begin(0)
        replacements << { value: value, offset: offset }
        "#{quote}#{STRING_SENTINEL * content.length}#{quote}"
      end

      pos = 0
      while (offset = selector.index("(", pos))
        value = gobble_parens(selector, offset)
        replacements << { value: value, offset: offset }
        placeholder = "(#{PLACEHOLDER_CHAR * (value.length - 2)})"
        selector = selector[0...offset] + placeholder + selector[(offset + value.length)..].to_s
        pos = offset + placeholder.length
      end

      tokens = tokenize_by(selector, grammar)
      changed_tokens = {}

      replacements.reverse_each do |replacement|
        tokens.each do |token|
          next unless token.is_a?(Hash)

          offset = replacement[:offset]
          value = replacement[:value]
          token_pos = token[:pos]
          next unless token_pos[0] <= offset && (offset + value.length) <= token_pos[1]

          content = token[:content]
          token_offset = offset - token_pos[0]
          token[:content] =
            content[0...token_offset].to_s +
            value +
            content[(token_offset + value.length)..].to_s
          changed_tokens[token.object_id] = token
        end
      end

      changed_tokens.each_value do |token|
        pattern = get_argument_pattern_by_type(token[:type])
        raise ArgumentError, "Unknown token type: #{token[:type]}" unless pattern

        match = pattern.match(token[:content])
        unless match
          raise ArgumentError,
                "Unable to parse content for #{token[:type]}: #{token[:content]}"
        end

        match.named_captures.each do |key, value|
          token[key.to_sym] = value
        end
      end

      tokens
    end

    def nest_tokens(tokens, list: true)
      if list && tokens.any? { |t| t[:type] == "comma" }
        selectors = []
        temp = []

        tokens.each_with_index do |token, index|
          if token[:type] == "comma"
            raise ArgumentError, "Incorrect comma at #{index}" if temp.empty?

            selectors << nest_tokens(temp, list: false)
            temp = []
          else
            temp << token
          end
        end

        raise ArgumentError, "Trailing comma" if temp.empty?

        selectors << nest_tokens(temp, list: false)
        return { type: "list", list: selectors }
      end

      (tokens.length - 1).downto(0) do |i|
        token = tokens[i]
        next unless token[:type] == "combinator"

        left = tokens[0...i]
        right = tokens[(i + 1)..] || []

        if left.empty?
          return {
            type: "relative",
            combinator: token[:content],
            right: nest_tokens(right)
          }
        end

        return {
          type: "complex",
          combinator: token[:content],
          left: nest_tokens(left),
          right: nest_tokens(right)
        }
      end

      case tokens.length
      when 0
        raise ArgumentError, "Could not build AST."
      when 1
        tokens.first
      else
        { type: "compound", list: tokens.dup }
      end
    end

    def flatten(node, parent = nil, &block)
      return enum_for(:flatten, node, parent) unless block_given?

      case node[:type]
      when "list"
        node[:list].each { |child| flatten(child, node, &block) }
      when "complex"
        flatten(node[:left], node, &block)
        flatten(node[:right], node, &block)
      when "relative"
        flatten(node[:right], node, &block)
      when "compound"
        node[:list].each { |token| block.call(token, node) }
      else
        block.call(node, parent)
      end
    end

    def walk(node, visit = nil, parent = nil, &block)
      visitor = visit || block
      raise ArgumentError, "No visitor provided" unless visitor
      return if node.nil?

      flatten(node, parent).each do |token, ast|
        visitor.call(token, ast)
      end
    end

    def parse(selector, recursive: true, list: true)
      tokens = tokenize(selector)
      return nil if tokens.empty?

      ast = nest_tokens(tokens, list: list)
      return ast unless recursive

      flatten(ast).each do |token, _|
        next unless token[:type] == "pseudo-class"

        argument = token[:argument]
        next unless argument
        next unless RECURSIVE_PSEUDO_CLASSES.include?(token[:name])

        child_arg = RECURSIVE_PSEUDO_CLASSES_ARGS[token[:name]]
        if child_arg
          match = child_arg.match(argument)
          next unless match

          match.named_captures.each do |key, value|
            token[key.to_sym] = value
          end
          argument = match[:subtree]
        end

        next if argument.nil? || argument.empty?

        token[:subtree] = parse(argument, recursive: true, list: true)
      end

      ast
    end

    def stringify(list_or_node)
      return list_or_node.map { |token| token[:content] }.join if list_or_node.is_a?(Array)

      case list_or_node[:type]
      when "list"
        list_or_node[:list].map { |node| stringify(node) }.join(",")
      when "relative"
        list_or_node[:combinator] + stringify(list_or_node[:right])
      when "complex"
        stringify(list_or_node[:left]) +
          list_or_node[:combinator] +
          stringify(list_or_node[:right])
      when "compound"
        list_or_node[:list].map { |node| stringify(node) }.join
      else
        list_or_node[:content]
      end
    end

    def specificity_to_number(specificity, base = nil)
      base ||= specificity.max.to_i + 1
      (specificity[0] * (base << 1)) +
        (specificity[1] * base) +
        specificity[2]
    end

    def specificity(selector)
      ast = selector
      ast = parse(selector, recursive: true) if selector.is_a?(String)
      return [] unless ast

      if ast.is_a?(Hash) && ast[:type] == "list"
        base = 10
        specificities = ast[:list].map do |entry|
          sp = specificity(entry)
          base = [base, *sp].max
          sp
        end
        numbers = specificities.map { |sp| specificity_to_number(sp, base) }
        return specificities[numbers.index(numbers.max)]
      end

      ret = [0, 0, 0]
      flatten(ast).each do |token, _|
        case token[:type]
        when "id"
          ret[0] += 1
        when "class", "attribute"
          ret[1] += 1
        when "pseudo-element", "type"
          ret[2] += 1
        when "pseudo-class"
          next if token[:name] == "where"

          unless RECURSIVE_PSEUDO_CLASSES.include?(token[:name]) && token[:subtree]
            ret[1] += 1
            next
          end
          sub = specificity(token[:subtree])
          sub.each_with_index { |value, index| ret[index] += value }
          ret[1] += 1 if %w[nth-child nth-last-child].include?(token[:name])
        end
      end

      ret
    end
  end
end
