# initializer for the Coverpage module(s)
require 'coverpage'
if caller.last.match(/rake:\d+$/)
  # Use STDOUT if running as rake task
  FEEDBACK = Coverpage::Feedback.new
else
  # Otherwise use default log file
  FEEDBACK = Coverpage::Feedback.new(:output => Rails.root.join("log", "coverpage.log"))
end
