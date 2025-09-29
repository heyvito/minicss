# frozen_string_literal: true

module FixturePath
  def fixture_path(*) = File.join(__dir__, "..", "fixtures", *)
end
