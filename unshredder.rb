#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'RMagick'

class Unshredder < Object

  def initialize(file)
    @file = file
    @strips = []
    @sortedStrips = []
    @compareNo = 0
    @stripWidth = 32
    
    if !FileTest.exists?(@file)
      puts 'File does not exist'
      return
    end
    
    getStrips()
    
    2.times do |comp|
      if @sortedStrips.count == @strips.count
        break
      end
      @compareNo = comp
      startSort()
    end
      
    outputImage()
  end
  
  #greatest common factor
  # def gcf(*args)
  #   allFactors = []
  #   args.each do |num|
  #     factors = []
  #     factor = 2
  #     while factor <= num/2
  #       if num % factor == 0
  #         factors << factor
  #       end
  #       factor++
  #     end
  #     allFactors << factors
  #   end
  #   
  #   result = allFactors.inject {|x, y| x & y }
  # end

  def getStrips()
    # getStripWidth()
    img = Magick::Image::read(@file).first
    
    xPos = 0
    id = 0
    
    @imageHeight = img.rows
    @imageWidth = img.columns
    
    while xPos < @imageWidth
      croppedImage = img.crop(xPos, 0, @stripWidth, @imageHeight, true)
      left = croppedImage.crop(0, 0, 1, @imageHeight, true)
      right = croppedImage.crop(@stripWidth - 1, 0, 1, @imageHeight, true)
      @strips.push({:id => id, :image => croppedImage, :left => left, :right => right})
      xPos += @stripWidth
      id += 1
    end
  end  
  
  def difference(a, b)
    difference = a.difference(b)
    difference[1]
  end
  
  def startSort()    
    @strips.each do |strip|
      sortedStrips = sort([strip], :right)
      if sortedStrips.count > @sortedStrips.count
        @sortedStrips = sortedStrips
      end
      if @sortedStrips.count == @strips.count
        return
      end
    end
  end
  
  def sort(sortedStrips, direction)    
    if sortedStrips.count == @strips.count
      return sortedStrips
    end
  
    if direction == :left
      opposite = :right
      currentStrip = sortedStrips.first
    else
      opposite = :left
      currentStrip = sortedStrips.last
    end
    
    nextStrip = getNext(currentStrip, direction)
    if getNext(nextStrip, opposite) == currentStrip
      if direction == :right
        sortedStrips.push(nextStrip)
      else
        sortedStrips.unshift(nextStrip)
      end
      sort(sortedStrips, direction)
    else
      if direction == :left
        return sortedStrips
      else
        sort(sortedStrips, :left)
      end
    end
  end
  
  def getNext(strip, direction)
    minDiff = 1000000
    closest = nil
    @strips.each do |compare|
      if compare[:id] != strip[:id]
        if direction == :left
          difference = strip[:left].difference(compare[:right])
        else
          difference = strip[:right].difference(compare[:left])
        end
        
        if difference[@compareNo] < minDiff
          minDiff = difference[@compareNo]
          closest = compare
        end
      end
    end
    closest
  end
  
  def outputImage
    il = Magick::ImageList.new
    puts @sortedStrips.size
    @sortedStrips.each do |strip|
      puts strip[:id]
      il.push(strip[:image])
    end
    ext = File.extname @file
    outputFile = "#{File.dirname(@file)}/#{File.basename(@file, ext)}_unshredded#{ext}"
    il.append(false).write(outputFile)
  end
end
