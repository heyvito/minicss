#!/usr/bin/env ruby

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
          write "tok = TinyCSS::CSS::Tokenizer.new(style)"
          write "tok.tokenize"
          write "par = TinyCSS::CSS::Parser.new(tok.tokens)"
          write "sheet = par.parse_stylesheet"
          write "r = TinyCSS::AST.convert(sheet)"
          write ""
          write "match_ast(r) do"
          inc do
            case opts&.fetch(:type)
            when :blocks
              run_blocks!(exp)
            when :component_value_list
              write "# #{opts[:type]}"
            when :declarations
              write "# #{opts[:type]}"
            when :component_value
              write "# #{opts[:type]}"
            when :declaration
              write "# #{opts[:type]}"
            when :rule
              write "# #{opts[:type]}"
            when :rule_list
              write "# #{opts[:type]}"
            when :stylesheet
              write "# #{opts[:type]}"
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

  def run_blocks!(exp)
    return if exp.nil?
    return write "empty!" if exp.empty?

    exp.each do |e|
      if e.is_a? String
        next if e == ";"
        write "string #{e.inspect}"
        next
      end

      case e.first
      when "declaration"
        name, body, important = e[1...]
        write "decl(#{name.dump}, important: #{important}) do"
        inc do
          run_blocks!(body)
        end
        write "end"
      when "{}"
        write "block(\"{\") do"
        inc do
          run_blocks!(e[1...])
        end
        write "end"
      when "[]"
        write "block(\"[\") do"
        inc do
          run_blocks!(e[1...])
        end
        write "end"
      when "()"
        write "block(\"(\") do"
        inc do
          run_blocks!(e[1...])
        end
        write "end"
      when "ident"
        write "ident #{e[1].inspect}"
      when "number"
        raw, value, type = e[1...]
        write "number #{raw.inspect}, :#{type}"
      when "string"
        write "string #{e[1].inspect}"
      when "at-rule"
        name, prelude, block = e[1...]
        write "at_rule(#{name.inspect}) do"
        inc do
          write "prelude do"
          inc do
            run_blocks! prelude
          end
          write "end"
        end

        unless body.nil?
          write "body do"
          inc do
            run_blocks! block
          end
          write "end"
        end
        write("end")
      when "qualified rule"
        prelude, block = e[1...]
        write "q_rule do"
        inc do
          write "prelude do"
          inc do
            run_blocks! prelude
          end
          write "end"

          write "body do"
          inc do
            run_blocks! block
          end
          write "end"
        end
        write "end"
      else
        write "# TODO: #{e.first}"
      end
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
  "stylesheet_bytes.json" => nil,
}

files.each do |file, opts|
  data = File.read(File.join("spec", "fixtures", "css-parsing-tests", file))
  data = JSON.parse(data)
  app = App.new(file, data, opts)
  app.run!
  val = app.value.split("\n").map(&:rstrip).join("\n")
  v, * = file.split(".")
  File.write(File.join("spec", "parsing_tests", "#{v}_spec.rb"), val)
end
