# frozen_string_literal: true

require "minicss"

begin
  require "ruby-prof"
rescue LoadError
  abort "[profiling] ruby-prof is not available; install it with `bundle install --with benchmark --with profiling` or `gem install ruby-prof`."
end

DEFAULT_FIXTURE = File.expand_path("./bootstrap-4.css", __dir__)
CSS_PATH = File.expand_path(ENV.fetch("PROFILE_CSS", DEFAULT_FIXTURE))
CSS_CONTENT = File.read(CSS_PATH)
SERIALIZATION_AST = MiniCSS.parse(CSS_CONTENT)
PARSING_PARSER = MiniCSS::CSS::Parser.new(MiniCSS.tokenize(CSS_CONTENT, allow_unicode_ranges: false))
CONVERT_AST = MiniCSS::CSS::Parser.new(MiniCSS.tokenize(CSS_CONTENT, allow_unicode_ranges: false)).parse_stylesheet

PROFILE_OPTIONS = { measure_mode: RubyProf::WALL_TIME }.freeze

def profile(operation)
  puts "\n== Profiling #{operation} =="
  profiler = RubyProf::Profile.new(**PROFILE_OPTIONS)
  result = profiler.profile { yield }
  RubyProf::FlatPrinter.new(result).print($stdout, min_percent: 2)
end

profile("MiniCSS.tokenize (#{File.basename(CSS_PATH)})") do
  MiniCSS.tokenize(CSS_CONTENT)
end

profile("MiniCSS.parse (#{File.basename(CSS_PATH)})") do
  PARSING_PARSER.parse_stylesheet
end

profile("MiniCSS.convert (#{File.basename(CSS_PATH)})") do
  MiniCSS::AST.convert(CONVERT_AST)
end

profile("MiniCSS.serialize (#{File.basename(CSS_PATH)})") do
  MiniCSS.serialize(SERIALIZATION_AST)
end
