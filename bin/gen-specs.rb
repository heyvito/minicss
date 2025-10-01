#!/usr/bin/env ruby
# frozen_string_literal: true

require "debug"
require "json"

class App
  attr_accessor :data, :opts, :out, :filename

  def initialize(file, data, opts)
    @data = data
    @opts = opts
    @out = []
    @filename = file
    @level = 0
  end

  def inc
    if block_given?
      @level += 1
      yield
      @level -= 1
      return
    end

    @level += 1
  end

  def dec
    @level -= 1
  end

  def write(*what)
    what.each do |l|
      @out << ("  " * @level)
      @out << l
      @out << "\n"
    end
  end

  def value
    @out.join
  end

  def run!
    write "RSpec.describe \"css-parsing-tests: #{filename}\" do"
    inc do
      @data.each_slice(2) do |input, exp|
        next unless input.is_a? String

        name = "parses #{input.dump}"
        write "it #{name.dump} do"
        inc do
          write "style = #{input.dump}"
          write "tok = MiniCSS::CSS::Tokenizer.new(style, allow_unicode_ranges: true)"
          write "tok.tokenize"
          write "par = MiniCSS::CSS::Parser.new(tok.tokens)"
          case @opts.fetch(:type)
          when :blocks, :declarations
            write "sheet = par.parse_block_contents"
          when :component_value_list
            write "sheet = par.parse_component_value_list"
          when :component_value
            write "sheet = [par.parse_component_value]"
          when :declaration
            write "sheet = [par.parse_declaration]"
          when :rule
            write "sheet = [par.parse_rule]"
          when :rule_list
            write "sheet = par.parse_stylesheet_contents"
          when :stylesheet
            write "sheet = par.parse_stylesheet"
          end
          write "r = MiniCSS::AST.convert(sheet)"
          write ""
          write "match_ast(r) do"
          inc do
            case opts&.fetch(:type)
            when :blocks, :declarations
              run_blocks!(exp)
            when :component_value_list, :stylesheet, :rule_list
              run_blocks!(exp, strip_spaces: false)
            when :component_value, :declaration, :rule
              run_single!(exp, strip_spaces: false)
            end
          end
          write "end"
        end
        write "end"
        write ""
      end
    end
    write "end"
  end

  DELIM_TOKENS = ["/", " ", ".", "~", ",", "*", "-->", ">", "\\", "@", "#", "=", "?", "+", "-", "|", "^", "$", "<!--", ":", ";", "]", ")", "!"].freeze

  def run_single!(exp, strip_spaces: true)
    return if exp.nil?
    return write "empty!" if exp.empty?

    if exp.is_a? String
      if DELIM_TOKENS.include?(exp)
        write("delim #{exp.inspect}")
      else
        write "string #{exp.inspect}"
      end
      return
    end

    if strip_spaces
      exp.shift while exp.first == " "
      exp.pop while exp.last == " "
    end

    case exp.first
    when "declaration"
      name, body, important = exp[1...]
      raise "incomplete delcaration specification: #{exp}. Missing last argument 'important'" if important.nil?

      write "decl(#{name.dump}, important: #{important}) do"
      inc do
        run_blocks!(body, strip_spaces:)
      end
      write "end"
    when "{}"
      write "block(\"{\") do"
      inc do
        run_blocks!(exp[1...], strip_spaces:)
      end
      write "end"
    when "[]"
      write "block(\"[\") do"
      inc do
        run_blocks!(exp[1...], strip_spaces:)
      end
      write "end"
    when "()"
      write "block(\"(\") do"
      inc do
        run_blocks!(exp[1...], strip_spaces:)
      end
      write "end"
    when "ident"
      write "ident #{exp[1].inspect}"
    when "number"
      value, type = exp[2...]
      write "number #{value}, :#{type}"
    when "string"
      write "string #{exp[1].inspect}"
    when "at-rule"
      name, prelude, block = exp[1...]
      write "at_rule(#{name.inspect}) do"
      inc do
        write "prelude do"
        inc do
          run_blocks! prelude, strip_spaces:
        end
        write "end"
      end

      unless body.nil?
        write "body do"
        inc do
          run_blocks! block, strip_spaces:
        end
        write "end"
      end
      write("end")
    when "qualified rule"
      prelude, block = exp[1...]
      write "q_rule do"
      inc do
        write "prelude do"
        inc do
          run_blocks! prelude, strip_spaces:
        end
        write "end"

        write "body do"
        inc do
          run_blocks! block, strip_spaces:
        end
        write "end"
      end
      write "end"
    when "dimension"
      val, type, unit = exp[2...]
      type = type.to_sym
      write "dimension(#{val}, #{type.inspect}, #{unit.dump})"
    when "function"
      write "function(#{exp[1].dump}) do"
      inc do
        run_blocks! exp[2...], strip_spaces:
      end
      write "end"
    when "at-keyword"
      write("at_keyword(#{exp[1].dump})")
    when "hash"
      write("hash_keyword(#{exp[1].dump})")
    when "error"
      write("consume_error(#{exp[1].dump})")
    when "url"
      write("url(#{exp[1].dump})")
    when "percentage"
      val, kind = exp[2...]
      write("percentage(#{val}, :#{kind})")
    when "unicode-range"
      start_at, end_at = exp[1...]
      write("unicode_range(#{start_at}, #{end_at})")
    else
      write "# TODO: #{e.first}!"
    end
  end

  def run_blocks!(exp, strip_spaces: true)
    return if exp.nil?
    return write "empty!" if exp.empty?

    if strip_spaces
      exp.shift while exp.first == " "
      exp.pop while exp.last == " "
    end

    exp.each do |e|
      run_single!(e, strip_spaces:)
    end
  end
end

files = {
  "blocks_contents.json" => { type: :blocks },
  "component_value_list.json" => { type: :component_value_list },
  "declaration_list.json" => { type: :declarations },
  "one_component_value.json" => { type: :component_value },
  "one_declaration.json" => { type: :declaration },
  "one_rule.json" => { type: :rule },
  "rule_list.json" => { type: :rule_list },
  "stylesheet.json" => { type: :stylesheet },
  "stylesheet_bytes.json" => nil
}

files.each do |file, opts|
  data = File.read(File.join("spec", "fixtures", "css-parsing-tests", file))
  data = JSON.parse(data)
  app = App.new(file, data, opts)
  app.run!
  val = app.value.split("\n").map(&:rstrip).join("\n")
  val = [
    "# frozen_string_literal: true",
    "",
    "# Autogenerated code. This code was generated by bin/gen-specs.rb. DO NOT EDIT.",
    "# Edits will be lost once the generator is run again.",
    "",
    ""
  ].join("\n").concat(val)
  v, * = file.split(".")
  File.write(File.join("spec", "parsing_tests", "#{v}_spec.rb"), val)
end
