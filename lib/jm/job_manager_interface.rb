require_relative 'job_manager'
require_relative 'job'

module JM
  module JobManagerInterface
    def job_manager_start max = nil
      job_manager.start(max)
    end
  
  
    def submt_job job
      job_manager.submit_job job
    end  
  
    def start
      job_manager.start
    end
    
    def stop
      job_manager.stop
    end
  
    def job_manager
      @job_manager  ||= JobManager.new 
    end
    
    # Create Job Object and submits it to the job manager
    def manage_job action, handlers = {}, name = "undefined_job", start_after = nil
      
      submt_job(JM::Job.new(action,nil, handlers, "test_job_default_handler" ))
      
    end
  
  end
end