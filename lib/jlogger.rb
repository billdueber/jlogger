require 'rubygems'
require 'rjack-logback'


# Redefine how to get logger names
module RJack
  module SLF4J
    def self.to_log_name classobject
      classline = []
      parent_is_a_logback = false
      loggingname = 'none'
      ancestors = []
      classobject.ancestors.each do |c|
        c = c.to_s
        if c == "JLogger::Simple"
          break
        end
        if c == "Object"
          break;
        end
        classline.unshift c.split('::')
      end
      loggingname = classline.flatten.join('.')
      return loggingname
    end
  end
end

# Allow access to teh underlying java logger
module RJack
  module Logback
    class Logger
      attr_reader :jlogger
    end
  end
end


# Create an outputstream logger
# Whoops. Nothing happens, and I don't know why. Don't worry about it for now.

# module RJack
#   module Logback
#     class StreamAppender < Java::ch.qos.logback.core.OutputStreamAppender
#       include AppenderUtil
# 
#       # Sets defaults, yields self to block, and calls self.start
#       def initialize( ioobject,  &block )
#         super()
#         set_defaults
#         self.setOutputStream(ioobject.to_outputstream)
#         self.encoding = "UTF-8"
#         finish( &block )
#       end
#     end
#   end
# end
# 


module JLogger
  module Simple
    include RJack::Logback

    Level = Java::ch.qos.logback.classic.Level
    LEVELS = {
      # :off => RJack::Logback::OFF,
      :off => Level::OFF,
      :trace => TRACE,
      :debug => DEBUG,
      :info => INFO,
      :warn => WARN,
      :error => ERROR,
    }
        
    def self.method_missing(meth, *args)
      @root.send(meth, *args)
    end
      
    

    # On inclusion, we set up a logger for this class
  
    def self.included klass
      @root ||= JLogger::RootLogger.new
      
      class << klass
        attr_accessor :_slflogger, :_logobject
      
        def createlogger
          RJack::Logback.root.jlogger.detachAppender('console')
          @_slflogger = RJack::SLF4J[self]
          @_logobject = RJack::Logback[@_slflogger.name]
          @_slflogger = @_logobject.jlogger
        end
        
        def log
          createlogger unless @_slflogger
          return @_slflogger
        end
      
        def loglevel= level
          self.createlogger unless @_slflogger
        
          level = level.to_s.downcase.to_sym
          unless LEVELS.has_key? level
            raise ArgumentError, "'#{level}' is an invalid loglevel"
          end
        
          @_logobject.level = LEVELS[level]
        end
      
      end
    end
  
  
    # The log object. First thing we do is try to 
    # get a logger from the class; if we can't, go
    # ahead and build one
  
    def log
      unless self.class._slflogger
        self.class.createlogger
      end
      return self.class._slflogger
    end
    
 
    
    
  end  
end


# The root logger

module JLogger
  class RootLogger
    include JLogger::Simple
    PATTERN = RJack::Logback::PatternLayout.new("%-5level\t%date{HH:mm:ss}\t%5r\t%-30logger\t%msg\n")
    
    def initialize
      self.class._logobject = RJack::Logback.root
      self.class._slflogger = self.class._logobject.jlogger
      RJack::Logback.root.jlogger.detachAppender('console')
    end
    
    # The logging methods
    
    def debug *args
      log.debug *args
    end
    
    def info *args
      log.info *args
    end

    def warn *args
      log.warn *args
    end

    def error *args
      log.error *args
    end
    
    
    def debug?
      return log.debug_enabled?
    end

    def info?
      return log.info_enabled?
    end

    def warn?
      return log.warn_enabled?
    end

    def error?
      return log.error_enabled?
    end
    
    # Set the log level
    # Why do I need to redefine this here? self.class.loglevel = level fails with
    # method not found.s
    
    def loglevel= level
      self.class.createlogger unless self.class._logobject
      level = level.to_s.downcase.to_sym
      unless JLogger::Simple::LEVELS.has_key? level
        raise ArgumentError, "'#{level}' is an invalid loglevel"
      end
    
      self.class._logobject.level = JLogger::Simple::LEVELS[level]
    end
    
    def startConsole pattern = nil
      return if  RJack::Logback.root.jlogger.getAppender('jlconsole')  
      jlconsole = RJack::Logback::ConsoleAppender.new do |a|
        a.target = "System.err"
        a.name = 'jlconsole'
        a.layout = pattern || PATTERN
      end
      RJack::Logback.root.add_appender( jlconsole )
    end

    def stopConsole
      RJack::Logback.root.jlogger.detachAppender('jlconsole')
    end
    
    
   
    def startFile file, pattern = nil
      
      # Get the ID and class to use
      
      id = nil
      mod = nil
      if file.is_a? String
         id = file
         mod = RJack::Logback::FileAppender
      # elsif file.respond_to? :to_outputstream
      #   id = 'objid' + file.object_id.to_s
      #   mod = RJack::Logback::StreamAppender
      else
        raise ArgumentError, "#{file} is not a valid target for file logging. Must be a filename"
      end
            
      return if  RJack::Logback.root.jlogger.getAppender(id)  
      
      app = mod.new(file) do |a|
        a.name = id
        a.layout = pattern || PATTERN
      end
      RJack::Logback.root.add_appender( app )
    end
    
    def stopFile file
      if file.is_a? String
         id = file
      # elsif file.respond_to? :to_outputstream
      #   id = 'objid' + file.object_id.to_s
      else
        raise ArgumentError, "#{file} is not a valid target for file logging"
      end
      RJack::Logback.root.jlogger.detachAppender(id)
    end
    
    
  end
end
    

