# frozen_string_literal: true

run proc { |_env| print "."; [201, { "Content-Type" => "text/plain" }, ["all good"]] }
