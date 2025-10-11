# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "minicss"

CRASS_AVAILABLE = begin
  require "crass"
  true
rescue LoadError
  warn "[benchmarks] Install crass (e.g. bundle install --with benchmark) to enable Crass comparisons"
  false
end

CRASS_SCAN = if CRASS_AVAILABLE
  ->(css) { Crass::Tokenizer.tokenize(css, preserve_comments: true) }
end

CRASS_PARSE = if CRASS_AVAILABLE
  if Crass.respond_to?(:parse)
    ->(css) { Crass.parse(css, preserve_comments: true) }
  elsif defined?(Crass::Parser) && Crass::Parser.respond_to?(:parse_stylesheet)
    ->(css) { Crass::Parser.parse_stylesheet(css, preserve_comments: true) }
  end
end

CRASS_STRINGIFY = if defined?(Crass::Parser) && Crass::Parser.respond_to?(:stringify)
  ->(tree) { Crass::Parser.stringify(tree) }
end

FIXTURE_PATH = File.expand_path("./bootstrap-4.css", __dir__)
FIXTURE_MIN_PATH = File.expand_path("./bootstrap-4.min.css", __dir__)
FIXTURES = [FIXTURE_PATH, FIXTURE_MIN_PATH].freeze

def run_suite(title, compare: true)
  puts "\n== #{title} =="
  Benchmark.ips do |x|
    x.config(time: ENV.fetch("BENCH_TIME", 5).to_i, warmup: ENV.fetch("BENCH_WARMUP", 1).to_i)
    yield x
    if compare && x.respond_to?(:compare!)
      begin
        x.compare!
      rescue StandardError => error
        warn "[benchmarks] compare! skipped: #{error.message}"
      end
    end
  end
end

FIXTURES.each do |fixture_path|
  css = File.read(fixture_path)
  minicss_ast = MiniCSS.parse(css)
  crass_serial_ast = CRASS_PARSE&.call(css)

  run_suite("Tokenize #{File.basename(fixture_path)}", compare: CRASS_SCAN) do |x|
    x.report("MiniCSS tokenize") { MiniCSS.tokenize(css) }
    if CRASS_SCAN
      x.report("Crass tokenize") { CRASS_SCAN.call(css) }
    end
  end

  run_suite("Parse #{File.basename(fixture_path)}", compare: CRASS_PARSE) do |x|
    x.report("MiniCSS parse") { MiniCSS.parse(css) }
    if CRASS_PARSE
      x.report("Crass parse") { CRASS_PARSE.call(css) }
    end
  end

  run_suite("Serialize #{File.basename(fixture_path)}", compare: CRASS_STRINGIFY && CRASS_PARSE) do |x|
    x.report("MiniCSS serialize") { MiniCSS.serialize(minicss_ast) }
    if CRASS_STRINGIFY && crass_serial_ast
      x.report("Crass stringify") { CRASS_STRINGIFY.call(crass_serial_ast) }
    end
  end
end
