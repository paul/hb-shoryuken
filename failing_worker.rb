# frozen_string_literal: true

# Start with:
# $ shoryuken -q test-hb-deadlock -r ./failing_worker.rb

require "honeybadger"
require "shoryuken"

# Shoryuken logs using `time.utc.iso8601`, which doesn't print fractional seconds by default
# https://github.com/phstc/shoryuken/blob/master/lib/shoryuken/logging.rb#L9
class Time
  def iso8601(_fraction_digits = 0)
    xmlschema(6)
  end
end

Honeybadger.configure do |config|
  config.api_key = "1234"
  config.logger = Shoryuken.logger
  config.connection.secure = false
  config.connection.host = "localhost"
  config.connection.port = 9292
end

Shoryuken.sqs_client = Aws::SQS::Client.new(logger: Shoryuken.logger)

Shoryuken.options[:delay] = 0
Shoryuken.options[:timeout] = 8
Shoryuken.sqs_client_receive_message_opts = {
  wait_time_seconds: 20,
  max_number_of_messages: 5
}

class FailingWorker
  include Shoryuken::Worker

  shoryuken_options queue: "test-hb-deadlock", auto_delete: true

  Error = Class.new(StandardError)

  def perform(_sqs_msg, options)
    Shoryuken.logger.debug(options)
    name, job = options.split(":")
    raise Error if job.to_i == 2
  end
end
