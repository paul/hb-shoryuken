# frozen_string_literal: true

require "time"
require "ostruct"
require "set"

require "awesome_print"
require "terminal-table"
require "term/ansicolor"

include Term::ANSIColor

@t0 = nil
@threads = Set.new

@events = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = Array.new } } # rubocop:disable Style/EmptyLiteral

@chunk = 10

def extract_ids(line)
  parts = line.split(" ")
  t = Time.iso8601(parts[0])
  tid = parts[2]
  jid = parts[3].split("/").last
  [t, tid, jid]
end

def offset(time)
  ((time - @t0).to_f * @chunk).to_i
end

def add_event(t, tid, msg)
  @threads << tid
  @events[offset(t)][tid] += [msg]
end

last_start = {}

File.open(ARGV[0]).each_line do |line|
  next unless line =~ /\sTID-/

  case line
  when /INFO: Starting/
    @t0, tid, _jid = extract_ids(line)

  when /started at/
    t, tid, jid = extract_ids(line)
    last_start[jid] = t
    add_event(t, tid, "Start #{jid.split('-').last}")

  when /INFO: completed in/
    t, tid, jid = extract_ids(line)
    duration = t - last_start[jid]
    add_event(t, tid, bold("Completed %0.2fms" % (duration * 1000)))

  when /INFO: failed in/
    t, tid, jid = extract_ids(line)
    duration = t - last_start[jid]
    add_event(t, tid, red("Failed %0.2fms" % (duration * 1000)))

  when /project is sending too many errors/
    t, tid, _jid = extract_ids(line)
    code = line.split(" ")[14]
    throttle = code.split("=").last.to_f
    add_event(t, "honeybadger", red(bold("Throttle #{'%0.2f' % throttle}")))

  end
end

finish = @events.keys.max
columns = @threads.to_a.sort.reverse

rows = []
0.step(finish) do |t|
  rows << ["%0.1f" % (t.to_f / @chunk), *columns.map { |tid| @events[t][tid].join("\n") }]
end

table = Terminal::Table.new do |table|
  table.headings = %w[t] + columns.to_a
  table.rows = rows
end

puts table
