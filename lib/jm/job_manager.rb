require 'thread'
require 'timeout'

module JM
class JobManager
  attr_accessor :max_jobs

  ###############################################
  # Queue Manipulation
  ###############################################
  def submit_job job
    return false if not exec_state or @queue.nil?
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
    if exec_state  and worker_exec_state
      puts "Job Manager already started, no need to start it again"    
    else
      puts "Job Manager starting with pool of #{@max_jobs} threads"
      @max_jobs = max unless max.nil?
      @queue = Queue.new if @queue.nil?
      
      # clean-up just in case.
      clean_up_workers
      
      # Turn on execution and crank up threads    
      start_monitor
      start_worker_threads
    end  
    
  end


  ##############################################################################################
  # Starts up 
  ##############################################################################################
  def start_worker_threads
    puts "Starting Job Manager capped at #{@max_jobs} jobs"
    worker_exec_state true
    @workers.size.upto((@max_jobs-1)) do |id|
      @workers.push(Thread.new{worker_exec_loop(id)})
    end
  end

  


  def start_monitor
    return if check_monitor_status
    # TODO: CLean-up dead monitor?
    exec_state true
    
    
    
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
    
    # Turn off execution to prevent new jobs from being added
    exec_state false
    
    # Wait for all jobs to finish,
    # and then shutdown the worker threads
    wait_for_workers_to_finish
    shutdown_workers
    
    # Now Shutdown the monitor
    shutdown_monitor
    
    puts "Job Manager has been completely stopped."
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
  
  # Politically correct way to stop all worker threads
  # immediatly.  We kill the sleepers and let the rest
  # expire after they finish their current job.
  def shutdown_workers     
    worker_exec_state false    
    kill_sleeping_workers    
  end
  
  
  # kills off a set number of workers, or all that are waiting at the queue
  def kill_sleeping_workers number =  @queue.num_waiting
    1.upto(number) do
      @queue << "kill"
    end
  end

  def wait_for_workers_to_finish
    puts "Waiting on #{@queue.length} Jobs to complete."
    jobs_left = @queue.length
    while 0 < @queue.length
      sleep (jobs_left*1)
      if jobs_left < @queue.length
        puts "Dude...quitting adding jobs while I'm waiting on the queue to empty. I'm breaking out. "
        break;
      end
      jobs_left = @queue.length
    end
    
    while @queue.num_waiting < @workers.count
      pending_threads = @workers.count - @queue.num_waiting
      puts "Waiting for #{pending_threads} threads to finish"
      sleep ( (2 * @queue.length) + (1 * @workers.count))      
    end    
  end
  
  
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

  #### Execution Loops #####
  
  #####################################################
  # Monitors workers and state.  Exits when execution
  # stops and all workers have been cleaned
  #####################################################
  def monitor_exec_loop
    puts "Monitor loop starting."
    
    delayed_shutdown_count = 0
    while exec_state or 0<worker_count
      sleep(20)
      clean_up_workers
      delayed_shutdown_count +=1 unless exec_state
      if 3 < delayed_shutdown_count
        # TODO: Need a graceful clean-up of stalled jobs
        puts "---> Breaking out of the monitor loop"
        break
      end
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
    
    puts "Job Thread #{id} started."
    while (true == worker_exec_state)
      puts "Job Thread #{id} waiting on next job."
      job = get_next_job
     
      if job.class == Job
        puts "Job Thread #{id} pulled Job: #{job.name}"
        begin 
          job.execute
        rescue => e
          Timeout::timeout(10)  {job.call_handler(e) }
        end        
      elsif job == "kill"
        break
      elsif job.nil?
        # NIL jobs are sometimes used to get around blocking
        puts "Job Thread #{id} - NIL Job encountered"
        sleep(0.25) 
        next
      else
        puts "Job Thread #{id} encountered non-job class."
      end
    end # WHILE
    puts "Job Thread #{id} gracefully shut down."
    poke_monitor # Tell monitor cycle to clean-up effeciently 
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
  
  def worker_exec_state change = nil
    with_state_mutex {
      @worker_exec = change unless change.nil?
      @worker_exec
    }
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
    @worker_exec= false    
    @workers_mutex = Mutex.new  # NOTE: Transcations should be short and sweet
    @state_mutex = Mutex.new  # NOTE: Transcations should be short and sweet    
    puts "Job Manager Created"
  end
  
  private
  
  #### Mutexes ####
  def with_workers_mutex
    @workers_mutex.synchronize { yield }
  end
      
      
  def with_state_mutex
    @state_mutex.synchronize { yield }
  end
end

end