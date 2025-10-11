# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "minicss"

SELECTORS = [
  "a[href^=https]::after",
  "button.primary:hover",
  "#main nav > ul > li.is-active > a",
  "[data-state~=expanded] .panel:nth-child(odd)",
  "article:nth-of-type(2n+1) .content::before"
].freeze

PARSED_SELECTORS = SELECTORS.map { MiniCSS::Sel.parse(_1) }

def run_suite(title)
  puts "\n== #{title} =="
  Benchmark.ips do |x|
    x.config(time: ENV.fetch("BENCH_TIME", 5).to_i, warmup: ENV.fetch("BENCH_WARMUP", 1).to_i)
    yield x
  end
end

run_suite("Selector parse (#{SELECTORS.size} selectors per iteration)") do |x|
  x.report("MiniCSS::Sel.parse") do
    SELECTORS.each { MiniCSS::Sel.parse(_1) }
  end
end

run_suite("Selector stringify (#{SELECTORS.size} selectors per iteration)") do |x|
  x.report("MiniCSS::Sel.stringify") do
    PARSED_SELECTORS.each { MiniCSS::Sel.stringify(_1) }
  end
end

run_suite("Selector specificity (#{SELECTORS.size} selectors per iteration)") do |x|
  x.report("MiniCSS::Sel.specificity") do
    PARSED_SELECTORS.each { MiniCSS::Sel.specificity(_1) }
  end
end
