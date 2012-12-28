#! /usr/bin/ruby

# https://github.com/k16shikano/isbn.rb
#
# * Licence
# Copyright (c) 2008, Keiichirou SHIKANO <k16.shikano@gmail.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

#    * Redistributions of source code must retain the above copyright
#      notice,this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#    * Neither the name of the Keiichirou SHIKANO nor the names of its
#      contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module ISBNtools
  # most methods take an Array containing ISBN digits.
  # 'cd' means 'check digit'.

  def cd10(raw)
    seed, cd = raw[0..8], raw[9]
    v = 11 - [10,9,8,7,6,5,4,3,2].zip(seed).map{|n,m| n*m}.inject(0){|i,j| i+j} % 11
    return v
  end

  def cd13(raw)
    seed, cd = raw[0..11], raw[12]
    v = (10 - [1,3,1,3,1,3,1,3,1,3,1,3].zip(seed).map{|n,m| n*m}.inject(0){|i,j| i+j} % 10) % 10
    return v
  end

  def put_cd10(raw); raw[0..8] + [cd10(raw)] end

  def put_cd13(raw); raw[0..11] + [cd13(raw)] end

  def put_cd(raw)
    by_length(raw, "put_cd10(raw)", "put_cd13(raw)")
  end

  def to_isbn(raw); by_length(raw, "cd10(raw)", "cd13(raw)") end

  def by_length(raw, do10, do13)
    if raw.length < 11; eval do10 else eval do13 end
  end

  def isbnchar(i) # needed only for ISBN-10
    case i
    when String then i
    when 0..9 then i.to_s
    when 10 then 'X'
    when 11 then '0'
    else '*'
    end
  end
end

class String
  def isbn_string; gsub(/[Xx]/, '0').gsub(/[^0-9]/, '') end

  # String -> ISBN
  def to_isbn
    ISBN.new(self)
  end
end

class Integer
  def digit(base)
    n, c = self, 0
    n, c = n/base, c+1 while n >= 1
    return c
  end

  # Integer -> ISBN
  def to_isbn
    ISBN.new(self)
  end
end

class Array
  include ISBNtools
  def to_isbn
    to_isbn_string.to_isbn
  end
  def to_isbn_string
    inject(''){|i,j| isbnchar(i) + isbnchar(j)}
  end
  def map_accum
    raw = []
    each_index{|i| raw << self[0..i].inject(0){|n,m| n+m}}
    return raw
  end
end

class ISBN
  include ISBNtools
  ISBN10_REGEX = /^(?:\d[\ |-]?){9}[\d|X]$/
  ISBN13_REGEX = /^(?:\d[\ |-]?){13}$/

  attr_accessor :raw, :seed, :is_valid

  def initialize(*seed)
    # Note: 
    #   seed is the initial argument
    #   raw is seed transposed to an array of integers
    @seed = seed[0]
    if @is_valid = is_valid?
      case @seed
      when String then d,s = @seed.length, @seed.isbn_string.to_i
      when Integer then d,s = @seed.digit(10), s = @seed
      end
      @raw = put_cd(Array.new(d <= 10 ? 10 : 13){|i| 10**i}.reverse.map{|ord| s/ord%10})
    else
      @raw
    end
  end

  def inspect
    if is_valid
      raw.to_isbn_string
    else
      seed
    end
  end

  # ISBN -> ISBN
  def isbn10
    return self.seed unless is_valid
    raw = self.raw
    by_length(raw,
              "put_cd10(raw[0..9])",
              "put_cd10(raw[3..11])").to_isbn
  end
  def isbn13
    return self.seed unless is_valid
    raw = self.raw
    by_length(raw,
              "put_cd13([9,7,8] + raw[0..8])",
              "put_cd13(raw[0..11])").to_isbn
  end

  def ==(other)
    self.isbn13.to_s == other.isbn13.to_s
  end

  # ISBN -> String
  def to_s(*blocks)
    return self.seed.to_s unless is_valid

    mark = '-'
    if blocks.length == 0
      hyphenate = nil
    else
      case blocks.last
      when String then mark = blocks.pop
      end
    end

    raw = self.raw.dup
    l = raw.length-1
    positions = blocks.map_accum.delete_if{|x| x > l || x <= 0}
    positions.push l unless positions.last == l || hyphenate.nil?
    positions.zip(Array.new(raw.length){|i| i}).map{|i,j| i+j}.each{|b|
      raw.insert(b, mark)
    }
    raw.to_isbn_string
  end

  def isbn13str
    return self.seed unless is_valid
    self.isbn13.to_s(3, 1, 5, 3, 1)
  end

  def isbn10str
    return self.seed unless is_valid
    self.isbn10.to_s(1, 5, 3, 1)
  end

  private

  # https://github.com/zapnap/isbn_validation
  #
  # Copyright © 2011 Nick Plante, released under the MIT license

  def is_valid?
    str = self.seed.to_s
    if str.match(ISBN13_REGEX)
      isbn_values = str.upcase.gsub(/\ |-/, '').split('')
      check_digit = isbn_values.pop.to_i # last digit is check digit
      sum = 0
      isbn_values.each_with_index do |value, index|
        multiplier = (index % 2 == 0) ? 1 : 3
        sum += multiplier * value.to_i
      end
      result = (10 - (sum % 10))
      result = 0 if result == 10
      result == check_digit
    elsif str.match(ISBN10_REGEX)
      isbn_values = str.upcase.gsub(/\ |-/, '').split('')
      check_digit = isbn_values.pop # last digit is check digit
      check_digit = (check_digit == 'X') ? 10 : check_digit.to_i
      sum = 0
      isbn_values.each_with_index do |value, index|
        sum += (index + 1) * value.to_i
      end
      result = sum % 11
      result == check_digit
    else
      false
    end
  end
end

