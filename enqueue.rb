# frozen_string_literal: true

require "./failing_worker"

jobs = (ARGV[0] || 10).to_i
name = (ARGV[1] || "first")
jobs.times do |i|
  FailingWorker.perform_async("#{name}:#{i}")
end
