#!/usr/bin/env ruby

require './unshredder'

if __FILE__ == $0
  if ARGV.count == 0
    puts 'You must provide an image to be unshredded'
  elsif ARGV.count == 1
    puts 'You must provide a strip width'
  else
    uns = Unshredder.new(ARGV[0], ARGV[1])
  end
end  