# Job -  Executes an action and optional post-processing/exception handling. It's intended purpose is to be executed by a thread manager.
#        The creator of jobs should be conservative when deciding the time-out period for the job.  A post processing/error handling
#        call-back can be defined. This counts against the jobs total execution time.  If a time-out occurs then the handler (if defined)
#        will be called with the Timeout::Error exception.  If an exception slips out of the execute operation, then a owner of the job
#        may call the handler directly.

require 'timeout'

module JM
  class Job
    attr_accessor :name, :state, :exception, :time_out, :input
  
    def initialize action, input =nil,  handler = nil, name = "undefined_job", time_out=10
      @action = action      # Sets the action to be performed by the job          
      @input = input        # Input into the Action being executed.
      @handler = handler    # Optional lambda call back from Job for any post-procesing/job handling. IMPORTANT- This work counts against the execution time-out.
      @name = name          # Name give to the job
      @time_out = time_out  # Indicates when to assume execution has stalled      
      @state = "pending"    # Current State of the Job
      @exception = nil      # Exception (if any) encoutnered during execution    
        
      puts "Job Created: #{name}"
    end
      
    # Executes the job and calls the handler if it is turned on.
    def execute input =nil
      Timeout::timeout(@time_out) {
        @state = "started"
        @input = input unless input.nil?          
        handler_input =nil
        
        begin
          @state = @action.call(@input)
          puts "Job #{@name} action complete."
          handler_input = @state 
        rescue => e
          puts "Job #{@name} encountered exception during execution: #{e.message}"
          @exception = e            
          @state= "exception"                                    
          handler_input= e
        end
        
        # Call handler if turned on
        call_handler handler_input
      }        
    rescue Timeout::Error => e
      call_handler(e)      
    ensure
      # Return the state of the job
      @state
    end
      
      
    # Calls Handler and updates state if error
    def call_handler(handler_input=nil)        
      @handler.call (handler_input) unless @handler.nil?           
    rescue => e
      puts "Job #{@name} encountered exception raised from handler call: #{e.message}"
      @exception = e  unless not @exception.nil?  # Don't overwrite previous exception
      @state="handler_exception"
    ensure
      @state  
    end
    
  end # Class
end # Module