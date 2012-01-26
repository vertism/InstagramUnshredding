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
  def gcf(*args)
    allFactors = []
    args.each do |num|
      factors = []
      factor = 2
      while factor <= num/2
        if num % factor == 0
          factors << factor
        end
        factor++
      end
      allFactors << factors
    end
    
    result = allFactors.inject {|x, y| x & y }
  end
  
  def getStripWidth()
    img = Magick::Image::read(@file).first
    diffs = []
    xPos = 0
    @imageWidth = img.columns
    
    lastLine = img.crop(xPos, 0, 1, @imageHeight, true)
    
    while xPos < @imageWidth
      currentLine = img.crop(xPos, 0, 1, @imageHeight, true)
      diffs << difference(lastLine, currentLine)
      
      lastLine = currentLine
      xPos++
    end
    
    sortedDiffs = diffs.sort { |a,b| b <=> a }
    top10Threshold = sortedDiffs[sortedDiffs/10]
    
    largestDiffIndexes = []
    diffs.each_by_index do |diff, index|
      if diff <= top10Threshold
        largestDiffIndexes << index
      end
    end
    
    
    
  end

  def getStrips()
    getStripWidth()
    
    img = Magick::Image::read(@file).first
    
    xPos = 0
    id = 0
    
    @imageHeight = img.rows
    @imageWidth = img.columns
    
    currentWidth = 0
    lastLine = img.crop(xPos, 0, 1, @imageHeight, true)
    lastDiff = 0
    xPos += 1
    
    while xPos < @imageWidth
      currentLine = img.crop(xPos, 0, 1, @imageHeight, true)
      currentDiff = difference(lastLine, currentLine)
      currentWidth += 1
      
      newSection = false
      
      if xPos + 1 == @imageWidth
        newSection = true
        currentWidth += 1
      elsif currentDiff > 0.06
        newSection = true
      elsif currentDiff > (lastDiff * 2.5)
        newSection = true
      elsif currentDiff > (lastDiff * 1.5) && currentDiff > 0.04
        nextLine = img.crop(xPos + 1, 0, 1, @imageHeight, true)
        nextDiff = difference(currentLine, nextLine)
        if nextDiff < 0.02
          newSection = true
        end
      end
      
      if newSection  
        puts '**************'
        puts currentWidth
        croppedImage = img.crop(xPos - currentWidth, 0, currentWidth, @imageHeight, true)
        left = croppedImage.crop(0, 0, 1, @imageHeight, true)
        right = croppedImage.crop(currentWidth - 1, 0, 1, @imageHeight, true)
        @strips.push({:id => id, :image => croppedImage, :left => left, :right => right})
        id += 1
        currentWidth = 0
      end
      xPos += 1
      puts currentDiff * 10
      lastLine = currentLine
      lastDiff = currentDiff
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
    il.append false
    il.write outputFile
  end
end
