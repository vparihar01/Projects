require 'fileutils'
include FileUtils

module Coverpage
  # = Coverpage Feedback Class
  
  class Feedback
    attr_accessor :level, :device

    IMPORTANT = 0
    VERBOSE   = 1
    DEBUG     = 2

    def initialize(options={})
      # Output to STDOUT or a file (as defined in options[:output])
      @device = options[:output] || $stderr
      # Level of feedback to be displayed (set to DEBUG when encountering errors)
      @level = DEBUG
    end

    def say(level, message, options = {})
      if level <= self.level
        (RUBY_VERSION >= "1.9" ? message.lines : message).each do |line|
          line = "#{line}\n" unless options[:print] == true
          if device.respond_to?(:puts)
            device.print line
          else
            File.open(device.to_str, "a") do |out|
              out.write "[#{Time.now}] #{line}"
            end
          end
        end
      end
    end
    
    def important(message, options = {})
      say(IMPORTANT, message, options)
    end

    def error(message, options = {})
      say(IMPORTANT, "! Error: #{message}", options)
    end

    def warning(message, options = {})
      say(IMPORTANT, "! Warning: #{message}", options)
    end

    def verbose(message, options = {})
      say(VERBOSE, message, options)
    end

    def debug(message, options = {})
      say(DEBUG, "# DEBUG: #{message}", options)
    end
    
    def print_variable(var, binding)
      puts "! Error: Must pass debug a string" unless var.is_a?(String) || var.is_a?(Array)
      var = var.to_a if var.is_a?(String)
      var.each { |x| important("#{x} = #{eval(x, binding).inspect}") }
    end
    
    def print_options(options)
      debug = options[:debug]
      verbose = options[:verbose]
      force = options[:force]
      print_variable(%w(debug verbose force), binding)
    end

    def print_record(record)
      debug("#{record.class.to_s}: #{record.name} (#{record.id})")
    end
  end

  class RailsEnvironment
    attr_reader :root, :public_path, :env

    def initialize(dir)
      @root = dir
      @public_path = File.join(dir, "public")
      @env = %w(development production).include?(ENV['RAILS_ENV']) ? ENV['RAILS_ENV'] : "development"
    end

    def self.find(dir=nil)
      dir ||= pwd
      while dir.length > 1
        return new(dir) if File.exist?(File.join(dir, 'config', 'environment.rb'))
        dir = File.dirname(dir)
      end
    end

    def self.default
      @default ||= find
    end

    def self.default=(rails_env)
      @default = rails_env
    end
  end

end
