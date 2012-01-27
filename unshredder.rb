#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'RMagick'

class Unshredder < Object

  def initialize(file, strip_width)
    @file = file
    @strips = []
    @sorted_strips = []
    @compare_no = 1

    
    if !FileTest.exists?(@file)
      puts 'File does not exist'
      return
    end
    
    get_strips()
    sort_strips()
    puts "output"
    output_image()
  end

  def get_strips()
    img = Magick::Image::read(@file).first
    
    x_pos = 0
    id = 0
    
    @image_height = img.rows
    @image_width = img.columns
    
    while x_pos < @image_width
      cropped_image = img.crop(x_pos, 0, @strip_width, @image_height, true)
      left = cropped_image.crop(0, 0, 1, @image_height, true)
      right = cropped_image.crop(@strip_width - 1, 0, 1, @image_height, true)
      @strips.push({:id => id, :image => cropped_image, :left => left, :right => right})
      x_pos += @strip_width
      id += 1
    end
  end  
  
  def sort_strips()   
    strip = find_first()
    @sorted_strips = sort([strip], :right)
  end
  
  def find_first()
    worst_strip = nil
    worst_difference = 0
    
    @strips.each do |strip|
      @strips.each do |compare|
        difference = strip[:left].difference(compare[:right])[@compare_no]
        if difference > worst_difference
          worst_difference = difference
          worst_strip = strip
        end
      end
    end
    
    worst_strip
  end
  
  def sort(sorted_strips, direction)    
    if sorted_strips.count == @strips.count
      return sorted_strips
    end
  
    if direction == :left
      opposite = :right
      current_strip = sorted_strips.first
    else
      opposite = :left
      current_strip = sorted_strips.last
    end
    
    next_strip = get_next(current_strip, direction)
    if get_next(next_strip, opposite) == current_strip
      if direction == :right
        sorted_strips.push(next_strip)
      else
        sorted_strips.unshift(next_strip)
      end
      sort(sorted_strips, direction)
    else
      if direction == :left
        return sorted_strips
      else
        sort(sorted_strips, :left)
      end
    end
  end
  
  def get_next(strip, direction)
    min_diff = 1000000
    closest = nil
    @strips.each do |compare|
      if compare[:id] != strip[:id]
        if direction == :left
          difference = strip[:left].difference(compare[:right])[@compare_no]
        else
          difference = strip[:right].difference(compare[:left])[@compare_no]
        end
        
        if difference < min_diff
          min_diff = difference
          closest = compare
        end
      end
    end
    closest
  end

  def output_image
    il = Magick::ImageList.new
    puts @sorted_strips.size
    @sorted_strips.each do |strip|
      puts strip[:id]
      il.push(strip[:image])
    end
    ext = File.extname @file
    output_file = "#{File.dirname(@file)}/#{File.basename(@file, ext)}_unshredded#{ext}"
    il.append(false).write(output_file)
  end
end
