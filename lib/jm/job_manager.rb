require 'thread'
require 'timeout'

module JM
class JobManager
  attr_accessor :max_jobs

  ###############################################
  # Queue Manipulation
  ###############################################
  def submit_job job
    return if @exec== false or @queue.nil?
    @queue << job
    #sleep(0.25) # sleep to avoid allow work to pick it up
    @exec
  end

  def get_next_job
   return nil if @queue.nil?
   @queue.pop
  end
  
  #### Controls for Job Manager #####
  
  ###############################################
  # Starts Job Manager, including workers & monitor
  ###############################################
  def start(max = nil) 
    if @exec == true
      puts "Job Manager already started, no need to start it again"
      return @exec
    end
    
    puts "Job Manager starting with pool of #{@max_jobs} threads"
    @max_jobs = max unless max.nil?
    clean_up_workers
    @queue = Queue.new if @queue.nil?
    
    # Turn on execution and crank up threads
    @exec = true
    start_worker_threads
    @monitor = start_monitor
    
  end


  def start_worker_threads
    puts "Starting Job Manager capped at #{@max_jobs} jobs"
    @workers.size.upto((@max_jobs-1)) do |id|
      @workers.push(Thread.new{job_exec_loop(id)})
    end
  end

  #####################################################
  # Removes workers that aren't active
  #####################################################
  def clean_up_workers
    @workers.delete_if do |worker|
      good_state = check_thread_health worker
      delete = false
      if not good_state
        thread_status = thread_status_look_up worker.status
        puts "Encountered an expired worker. (#{thread_status})  Firing this one."
        worker.join
        delete = true
      end 
      delete
    end
  end


  def start_monitor
    return if check_monitor_status
    # TODO: CLean-up dead monitor
    
    @monitor = Thread.new {monitor_exec_loop }
    #TODO: Error handler
    puts "Started Job Manager Monitor"

    @monitor 
  end

  #### Stop/Shutdown Operations ####
  
  #####################################################
  # Stops all workers, monitor and closes the queue s
  #####################################################
  def stop
    puts "Stopping the Job Manager"
    status
    
    @max_jobs =0
    @exec = false
    
    shutdown_workers
    wait_for_workers_to_finish
    
    shutdown_monitor
    check_monitor_status
   
    #@queue = nil
   
  end
  
  def hard_stop
    @queue.clear
    stop
  end
  
  
  def shutdown_monitor
    return if @monitor.nil?
    @monitor.wakeup if @monitor.status == "sleep"
    @monitor.join
  end
  
  
  def shutdown_workers
    original_state = @exec
    @exec = false
    
    @workers.each do |worker|
      @queue << nil
      worker.wakeup if worker.status == "sleep"
    end

    @exec = original_state
    
  end

  def wait_for_workers_to_finish
    while @queue.num_waiting < @workers.count
      pending_threads = @workers.count - @queue.num_waiting
      puts "Waiting for #{pending_threads} threads to finish"
      sleep (2 * @queue.length)
      status
      clean_up_workers
    end
    puts "Workers Left: #{@workers.count}"
  end

  #### Execution Loops #####
  
  #####################################################
  # Execution Loops
  #####################################################
  def monitor_exec_loop
    puts "Monitor loop starting."
    while (@exec)
      sleep(60)
      clean_up_workers
    end
    puts "Monitor Thread gracefully shutting down."
  end

  ####################################################
  # Retrieves next job in queue and executes it within
  # in a time-out block.
  ####################################################
  def job_exec_loop id = nil
    
    puts "Job Thread #{id} started."
    while @exec==true or not @queue.empty?
      puts "Job Thread #{id} waiting on next job."
      job = get_next_job
     
      if job.class == Job
        puts "Job Thread #{id} pulled Job: #{job.name}"
        begin 
          Timeout::timeout(job.time_out) {job.execute}
        rescue => e
          job.call_handler(e)
        end
      elsif job.nil?
        # NIL jobs are sometimes used to get around blocking
        sleep(0.25) 
        next
      else
        puts "Job Thread #{id} encountered non-job class."
      end
    end
    puts "Job Thread #{id} gracefully shut down."
    #Thread.exit
  end

  
  #### Helpers ####
  
  ####################################################
  #
  ####################################################
  def check_thread_health thr
    return false if thr.nil?
    (["sleep", "run"].include?(thr.status))
  end
  
  def check_monitor_status
    check_thread_health @monitor   
  end
  
  def status
    puts "Queue Status - Length: #{@queue.length} Num Waiting: #{@queue.num_waiting}"
  end
  
  # Look-up string representing state of thread
  def thread_status_look_up status
    string = case 
    when status.class == String
      status
    when status.nil?
      "Terminated with exception."
    when status == false
      "Terminated normally"
    else
      "Weird state"
    end
    
    return string
    
  end
  
  #### State ####
  def queue_size
    @queue.length
  end
  
  def worker_count
    @workers.count
  end

  ####################################################
  # Constructor
  ####################################################
  def initialize
    @queue = Queue.new
    @monitor = nil
    @workers = [] 
    @max_jobs = 5
    @exec = false
    puts "Job Manager Created"
  end
end

end