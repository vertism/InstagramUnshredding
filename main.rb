#!/usr/bin/env ruby

require './unshredder'

if __FILE__ == $0
  if ARGV.count == 0
    puts 'You must provide an image to be unshredded'
  else
    ARGV.each do |a|
      uns = Unshredder.new(a)
    end
  end
end  