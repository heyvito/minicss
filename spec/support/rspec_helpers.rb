# frozen_string_literal: true

module RSpecHelpers
  def self.included(base)
    base.include RSpec::Matchers
  end

  def expect(...) = RSpec.current_example.example_group_instance.expect(...)
  def fail(...) = RSpec.current_example.example_group_instance.expect(...)
end
