# jlogger

A simple wrapper around rjack-logback to make your logging easy.


I wanted a way to just include a module and automatically get logging that integrated with the Java logging I already had. rjack-logback provided all the tools for me to make one.

```ruby

require 'jlogger'

class MyClass
  include JLogger::Simple
  def hello
    log.info "Calling hello" # 'log' method thanks to JLogger::Simple
    puts 'Hello'
  end
end


rootlog = JLogger::RootLogger.new

# Start some log output. By default, NO logging is done!

rootlog.startConsole # starts logging on STDERR
rootlog.startFile 'mylog.log' # starts logging to the file


c = MyClass.new

rootlog.info 'Hello'  # logs to both STDERR and the file mylog.log
c.hello # ditto

rootlog.loglevel = :warn # use :debug, :info, :warn, :error, or :off

rootlog.info 'hello'  # doesn't log to anywhere
c.hello # ditto

MyClass.loglevel = :info # set it just for this class and its subclasses

rootlog.info 'hello'  # doesn't log to anywhere
c.hello # logs again

rootlog.stopFile('mylog.log') # stop logging to the file
rootlog.stopConsole # stop logging to STDERR

```


## Bugs

I can't seem to write a good wrapper to allow the use of File handles (converted to Outputstreams); that's something I would really like.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

== Copyright

Copyright (c) 2010 BillDueber. See LICENSE for details.
