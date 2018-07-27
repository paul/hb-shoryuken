# frozen_string_literal: true

run proc { |_env| print "."; [429, { "Content-Type" => "text/plain" }, ["slow down"]] }
