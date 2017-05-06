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


  def job_manager
    @job_manager  ||= JobManager.new 
  end

end
end