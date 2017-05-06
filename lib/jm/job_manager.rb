require 'thread'
require 'timeout'

module JM
class JobManager
  attr_accessor :max_jobs

  ###############################################
  # Queue Manipulation
  ###############################################
  def submt_job job
    @queue << job
  end

  def get_next_job
   @queue.pop
  end
  
  
  ###############################################
  # Controls for Job Manager
  ###############################################
  def start(max = nil)
    @max_jobs = max unless max.nil?
    clean_up_workers
    start_worker_threads
    @monitor = start_monitor
  end


  def start_worker_threads
    puts "Starting Job Manager capped at #{@max_jobs} jobs"
    workers.size.upto((@max_jobs-1)) do
      @workers.push(Thread.new{job_exec_loop})
    end
  end


  def clean_up_workers
    workersa.delete_if do |worker|
      good_state = check_thread_status worker 
      if not good_state 
        puts "Encountered a crashed worker.  Firing this one and getting a new one"
        worker.kill
      end 
      good_state
    end
  end


  def start_monitor
    return if not check_monitor_statue
   
    puts "Starting Job Manager Thread..."
    @monitor = Thread.new {monitor_exec_loop }
    #TODO: Error handler

    @monitor 
  end

  def stop
    @max_jobs =0
    @exec = false
  end

  def wait_for_workers_to_finish
    workers.each do |x|

    end

  end

  #####################################################
  # Execution Loops
  #####################################################
  def monitor_exec_loop
    while (@exec)
      sleep(0.25)
      clean_up_workers
    end

  end

  # Retrieves next job in queue and executes it within
  # in a time-out block.
  def job_exec_loop
    while @exec==true
      job = get_next_job

      if job.class == Job
        begin 
          Timeout::timeout(job.timeout) {job.execute}
        rescue => e
          job.handle_exception(e)
        end
      else
        puts "Job Thread encountered non-job class."
        sleep(1)
      end
    end
  end

  ####################################################
  # Helpers
  ####################################################
  def check_thread_status thr
    (["sleep", "run"].include?(thr.status))
  end

  ####################################################
  # Constructor
  ####################################################
  def initialize
    @queue = Queue.new
    @monitor = nil
    @workers = [] 
    @nax_jobs = 5
    @exec = true
    puts "Job Manager Created"
  end
end

end