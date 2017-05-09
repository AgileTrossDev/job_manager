require_relative 'job_manager'
require_relative 'job'


module JM
  
  module_function # Creates module functions for the named methods.
  
  
  def job_manager logger =nil
    # NOTE: Used for conveniance.  Called by other funcions in module.  On the first call,
    # the instance is created, which sets the logger and max threads.  It is recommended
    # that you use the either 'start' if you want to use this interface or 'start_new_instance'
    # if you want a new instance of a started job mangaer that you will control outside this interface.
    @job_manager ||= JobManager.new(logger) 
  end
  
  
  def start_new_instance max = nil, logger =nil
    # Creates and starts a new instance and then returns it back to the caller
    jm = JobManager.new(logger)
    jm.start
    jm
  end
  
  
  def start max = nil, logger =nil
    # Starts up the Manager used in this interface, creating it on first call, which sets the logger and max threads.
    job_manager(logger).start(max)
  end
  
  
  def stop
    # Stops the Manager used by this interface
    job_manager.stop
    clean_up
  end

  def submit_job job
    job_manager.submit_job job
  end
  
  def clean_up
    @job_manager = nil
  end
  
  
  
  def set_logger i_logger
    #job_manager.logger(i_logger)  
  end
  
  # Create instance of a Job and submits it to the job manager
  def manage_job action,input =nil, handler = nil, name = "undefined_job", time_out=10, logger = job_manager.logger    
    submit_job(JM::Job.new(action,input, handler, name, time_out,logger))
  end
end