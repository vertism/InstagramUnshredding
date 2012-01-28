#!/usr/bin/env ruby

require 'RMagick'

class Unshredder < Object
  
  def initialize(filename)
    if !FileTest.exists?(filename)
      puts 'File does not exist'
      return
    end
    
    @filename = filename
    @shredded_image = Magick::Image::read(filename).first
    @strip_width = get_strip_width(@image)
    
    if @strip_width == 0
      puts 'Could not determine strip width'
      return
    else
      puts "strips are #{@strip_width} pixels wide"
    end
    
    @strips = get_strips
    @sorted_strips = sort_strips
    output_image
    
    puts 'type "open ' + @unshredded_filename + '" to view reconstructed image'
  end
  
  # calculates width of strips in image
  # 1. gets array of differences in pixels between each pair of 1 pixel wide slithers
  # 2. gets average of these differences
  # 3. looks for value of every nth difference in array starting with n=3
  # 4. if > 66% are above average then returns n
  # This calculation could be more robust but it works for all my test images
  def get_strip_width(img)
    differences = []
    
    current_slither = @shredded_image.crop(0, 0, 1, @shredded_image.rows, true)
    x_pos = 1
    
    while x_pos < @shredded_image.columns
      next_slither = @shredded_image.crop(x_pos, 0, 1, @shredded_image.rows, true)
      differences.push(image_difference(current_slither,next_slither))
      
      x_pos += 1
      current_slither = next_slither
    end
    
    average_difference = differences.inject(0, :+)/@shredded_image.columns
    
    (3..@shredded_image.columns/2).to_a.each do |distance|
      above_average_total = 0
      differences.each_with_index do |slither_difference, index|
        if (index + 1) % distance == 0 && slither_difference > average_difference
          above_average_total += 1
        end
      end
      if above_average_total * 1.5 > @shredded_image.columns / distance
        return distance 
      end
    end
    
    0
  end
  
  def image_difference(a, b)
    a.difference(b)[1]
  end

  def get_strips
    x_pos = 0
    id = 0
    strips = []
  
    while x_pos < @shredded_image.columns
      cropped_image = @shredded_image.crop(x_pos, 0, @strip_width, @shredded_image.rows, true)
      left = cropped_image.crop(0, 0, 1, @shredded_image.rows, true)
      right = cropped_image.crop(@strip_width - 1, 0, 1, @shredded_image.rows, true)
      strips.push({:id => id, :image => cropped_image, :left => left, :right => right})
      x_pos += @strip_width
      id += 1
    end
    
    strips
  end  
  
  def sort_strips
    strip = find_first
    sort([strip], :right)
  end
  
  def find_first
    worst_strip = nil
    worst_difference = 0
    
    @strips.each do |strip|
      @strips.each do |compare|
        difference = image_difference(strip[:left],compare[:right])
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
          difference = image_difference(strip[:left],compare[:right])
        else
          difference = image_difference(strip[:right],compare[:left])
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
    @sorted_strips.each do |strip|
      il.push(strip[:image])
    end
    ext = File.extname @filename
    @unshredded_filename = "#{File.dirname(@filename)}/#{File.basename(@filename, ext)}_unshredded#{ext}"
    il.append(false).write(@unshredded_filename)
  end
end