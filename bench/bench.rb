require 'benchmark/ips'
require './setup'

Benchmark.ips do |x|
  x.report('SA initialize') do
    User.new(public: '1', published_at: '2016-01-01', age: '23')
  end

  x.report('AR-T initialize') do
    Looser.new(public: '1', published_at: '2016-01-01', age: '23')
  end
end

Benchmark.ips do |x|
  x.report('SA accessors') do
    u = User.new
    u.public = '1'
    u.published_at = '2016-01-01'
    u.age = '23'
  end

  x.report('AR-T accessors') do
    u = Looser.new
    u.public = '1'
    u.published_at = '2016-01-01'
    u.age = '23'
  end
end

Benchmark.ips do |x|
  x.report('SA create') do
    User.create!(public: '1', published_at: '2016-01-01', age: '23')
  end

  x.report('AR-T create') do
    Looser.create(public: '1', published_at: '2016-01-01', age: '23')
  end
end
