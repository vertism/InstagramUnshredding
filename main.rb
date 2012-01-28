#!/usr/bin/env ruby

require './unshredder'

if __FILE__ == $0
  if ARGV.count == 0
    puts 'You must provide an image to be unshredded'
  else
    uns = Unshredder.new(ARGV[0])
  end
end  