require 'thread'
require 'timeout'

module JM
class JobManager
  
  
  ACTIVE = true
  OFF = false
  
  ####################################################
  # Constructor
  ####################################################
  def initialize
    @queue = Queue.new          # Holds pending job (FIO)
    @monitor = nil              # Thead monitoring Job Manager
    @workers = []               # Collection of Workers
    @max_jobs = 5               # Worker Cap
    @exec = false               # Indicates Job Manager is accepting jobs
    @monitor_exec = false       # Indicates Monitor should continue to run
    @worker_exec= false         # Indicates all Workers should continue to work
    @workers_mutex = Mutex.new  # NOTE: Transcations should be short and sweet
    @state_mutex = Mutex.new    # NOTE: Transcations should be short and sweet    
    puts "Job Manager Created"
  end

  ###############################################
  # Queue Manipulation
  ###############################################
  def submit_job job
    return false if OFF == exec_state or @queue.nil?
    @queue << job
    true
  end

  def get_next_job
   return nil if @queue.nil?
   @queue.pop
  end
  
  #### Controls for Job Manager #####
  
  ##############################################################################################
  # Starts Job Manager, including workers & monitor threads
  ##############################################################################################
  def start(max = nil) 
    if exec_state  and worker_exec_state and monitor_exec_state and @max_jobs == max
      puts "Job Manager already started, no need to start it again"    
    else
      puts "Job Manager starting up"
      
      # Prepare state for execution
      max_jobs max unless max.nil?
      worker_exec_state ACTIVE
      monitor_exec_state ACTIVE
      exec_state ACTIVE
            
      # clean-up just in case.
      clean_up_workers
      
      # Turn on execution and crank up threads    
      start_monitor
      start_worker_threads
    end  
    
  end


  #### Thread Launchers ####
  
  def start_worker_threads additional = 0
    # Makes sure we have the right number of workers executing. We can specify how many
    # more we would like to add, which will result in max_jobs being updated.
    #
    # NOTE: A negative input will not effect the worker pool
  
    max_jobs (additional + max_jobs)    if 0 <additional 
    
    # Can't do much if we are not active or the worker pool is full
    return if OFF == worker_exec_state or max_jobs <= worker_count
    
    puts "Work force is capped at #{@max_jobs}.  Now adding additional #{@max_jobs - worker_count}workers"
    
    # Grab current work force state 
    current_work_force = worker_count
    max = max_jobs-1
    
    # Add workers as needed
    with_workers_mutex {
      current_work_force.upto(max) do |id|
        begin
          @workers.push(Thread.new{worker_exec_loop("#{id}_#{Thread.current.object_id}")})
        rescue => e
          puts "Exception caught while starting a Worker Thread: #{e.message}"
        end
      end
    }
      
    nil
  end


  def start_monitor
    return if check_monitor_status or OFF == monitor_exec_state
    # TODO: CLean-up dead monitor?
    
    begin
      @monitor = Thread.new {monitor_exec_loop }
      puts "Started Job Manager Monitor"
    rescue =>e
      puts "Exception caught while launching the monitor thread. #{e.message}"
    end
    
    @monitor 
  end

  
  #####################################################
  # Stops all workers, monitor and closes the queue s
  #####################################################
  def stop
    puts "Stopping the Job Manager"
    
    # Turn off execution to prevent new jobs from being added
    exec_state false
    
    # Wait for all jobs to finish  and then shutdown the worker threads
    wait_for_pending_work_to_complete
    shutdown_workers
    
    # Now Shutdown the monitor
    shutdown_monitor
    
    puts "Job Manager has been completely stopped."
  end
  
  def hard_stop
    # Empty queue, cancelling all pending jobs
    exec_state false
    @queue.clear
    stop
  end
  
  
  def shutdown_monitor
    return if @monitor.nil?
    monitor_exec_state false
    @monitor.wakeup if @monitor.status == "sleep"
    @monitor.join # TODO: Handle termination of monitor thread
    @monitor = nil
  end
  
  # Politically correct way to gracefully let current
  # work complete, before killing all the workers.
  # Kill action are added to the queue for all the
  # slazy sleeping workerx
  def shutdown_workers num = worker_count
    max_jobs ((max_jobs) -num)
    if num == worker_count or 0 == max_jobs
      puts "Gracefully shutting down all workers in the pool"
      worker_exec_state false   
      kill_sleeping_workers @queue.num_waiting
      wait_for_workers_to_finish
    else
      puts "Shutting down #{num} workers.  Remaining #{max_jobs} Workers will continue to execute."
      kill_sleeping_workers num 
    end
  end
  
  #### Execution Loops #####
  
  #####################################################
  # Monitors workers and state.  Exits when execution
  # stops and all workers have been cleaned
  #####################################################
  def monitor_exec_loop
    puts "Monitor loop starting."
    
    while monitor_exec_state or 0<worker_count
      sleep(20)
      clean_up_workers
      start_worker_threads
    end
    puts "Monitor Thread gracefully shutting down."
  end

  ####################################################
  # Retrieves next job in queue and executes it within
  # in a time-out block set by the job object.  The
  # loop will execute until worker execution state changes
  # or the worker pulls a kill message from the queue.
  ####################################################
  def worker_exec_loop id = nil
    
    puts "Worker Thread #{id} started."
    while (true == worker_exec_state)
      puts "Worker Thread #{id} waiting on next job."
      job = get_next_job
     
      if job.class == Job
        puts "Worker Thread #{id} pulled Job: #{job.name}"
        begin 
          job.execute
        rescue => e
          Timeout::timeout(10)  {job.call_handler(e) } rescue nil
        end        
      elsif job == "kill"
        puts "Worker Thread #{id} recieved kill notification"
        break
      elsif job.nil?
        # NIL jobs are sometimes used to get around blocking
        puts "Worker Thread #{id} - NIL Job encountered"
        sleep(0.25) 
        next
      else
        puts "Worker Thread #{id} encountered a job it does not know how to handle"
      end
    end # WHILE
    puts "Worker Thread #{id} gracefully shut down."
    poke_monitor # Tell monitor cycle to clean-up effeciently 
   
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
    puts "Queue Status - Length: #{@queue.length} Num Waiting: #{@queue.num_waiting} Workers: #{worker_count}"
  end
  
  # Wake-up monitor from sleep for faster reaction
  def poke_monitor
    @monitor.wakeup if not @monitor.nil? and @monitor.status == "sleep"
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
    
  def queued_jobs
    @queue.length
  end
  
  
  def worker_count
    with_workers_mutex { @workers.count }
  end
  
  
  def exec_state change = nil
    with_state_mutex {
      @exec = change unless change.nil?
      @exec
    }
  end
  
  def monitor_exec_state change = nil
    with_state_mutex {
      @monitor_exec = change unless change.nil?
      @monitor_exec
    }
    
  end
  
  def monitor_health_check
    # Monitor is healthy if it is running or sleeping
   ( (not @monitor.nil?) and (@monitor.status =="run" or @monitor.status == "sleep")) 
  end
  
  def worker_exec_state change = nil
    with_state_mutex {
      @worker_exec = change unless change.nil?
      @worker_exec
    }
  end
  
  def max_jobs change = nil
    with_state_mutex {
      @max_jobs = change unless change.nil?
      @max_jobs = 0 if @max_jobs <0
      @max_jobs
    }
  end
  
  private
  
  #### Internal Helpers ####
  
  
  
  #### Stop/Shutdown Operations ####
  
  
  #####################################################
  # Removes workers that aren't active
  #####################################################
  def clean_up_workers
    with_workers_mutex {
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
    }
  end
    
  def kill_sleeping_workers number =  worker_count
    # kills off a set number of workers, or all of them
    # NOTE: Jobs entered in the queue before or during this phase will also be executed.
    #      
    1.upto(number) do
      @queue << "kill"
    end
    
    remaining = @queue.length - number
    remaining = 0 if remaining <0
    puts "#{number} out of #{worker_count} set to terminate with an estimated #{remaining} jobs remaining. "
  end
  
  
  def wait_for_workers_to_finish
    # Assumes that workers are already finalizing work and shutting down
    # NOTE: Any additional work added to the queue will not be worked
    # NOTE: If possible relies on monitor to perform clean-up
    puts "Waiting on #{worker_count} worker to finalize."
    
    while 0< worker_count and monitor_exec_state
      sleep (2)
      clean_up_workers unless monitor_health_check
    end    
  end
    
  def wait_for_pending_work_to_complete
    
    # Assumes no new jobs will be submitted and that active workers will complete the work.
    raise "No workers to perform final #{@queue.num_waiting} jobs" if 0 == worker_count and 0< @queue.length
    raise "Can't wait for work to complete while actively accepting jobs."  if ACTIVE == exec_state
    
    puts "Waiting on #{@queue.length} Jobs to execute."
    while 0 < @queue.length and OFF == exec_state and  0< worker_count
      sleep (@queue.length*1)
    end
    
    if 0 ==@queue.length
      puts "Queue is empty.  Workers may still be actively executing jobs"
    else
      puts "Queue is not empty. State must have changed that prevented final #{@queue.length} pending jobs to complete."
    end
      
  end
  
  #### Mutexes ####
  def with_workers_mutex
    @workers_mutex.synchronize { yield }
  end
      
      
  def with_state_mutex
    @state_mutex.synchronize { yield }
  end
end

end