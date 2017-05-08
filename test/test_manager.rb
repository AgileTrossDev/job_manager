require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job_manager.rb"
require "helper"

class TestJobManager < Minitest::Test
  
  include TEST
  
  
   
  def setup
    @test_suite = "TestJobManager"  
  end
  
  def teardown
    common_teardown
  end
  
  
  def test_job_manager_create
      set_test_step_name "test_job_manager_create"
      jm = JM::JobManager.new
      assert_equal false, jm.nil? 
  end
  
  def test_job_manager_start_stop
      set_test_step_name "test_job_manager_start_stop"
      jm = JM::JobManager.new
      assert_equal false, jm.nil?
      
      jm.start
      sleep(2)
      assert_equal true, jm.check_monitor_status
      assert_equal true, jm.exec_state
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queued_jobs
      assert_equal 0, jm.worker_count
      assert_equal false, jm.exec_state
      
  end
  
  
  def test_job_manager_submit_single_job
      set_test_step_name "test_job_manager_submit_single_job"
      jm = JM::JobManager.new
      assert_equal false, jm.nil?
      
      jm.start
      assert_equal true, jm.exec_state
      
      job = generic_job "TEST_SINGLE_JOB", "Happy Input"
      result = jm.submit_job(job)
      assert_equal true, result
      assert_equal true, jm.check_monitor_status
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queued_jobs
      assert_equal 0, jm.worker_count
      assert_equal true, job.state
      
  end
  
  def test_job_manager_submit_multiple_jobs
      set_test_step_name "test_job_manager_submit_multiple_jobs"
      jm = JM::JobManager.new
      assert_equal false, jm.nil?
      
      jm.start
      assert_equal true, jm.exec_state
      
      jobs = []
      1.upto(100) do |x|
        job = sleepy_job "TEST_MULTI_JOB_#{x}", "Happy Input"
        jobs.push job
        result = jm.submit_job(job)
        assert_equal true, result
      end
      
      assert_equal true, jm.check_monitor_status
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queued_jobs
      assert_equal 0, jm.worker_count
      
      jobs.each do |job|
        assert_equal true, job.state
      end
  end
  
  def test_job_manager_worker_counter_larger
    set_test_step_name "test_job_manager_worker_counter_larger"
  end
  
  def test_job_manager_worker_counter_smaler
    set_test_step_name "test_job_manager_worker_counter_smaler"
  end
  
  
  # Submits a Job to a manager that was never started.
  def test_job_manager_submit_to_stop_manager
    set_test_step_name "test_job_manager_submit_to_stop_manager"
    
    jm = JM::JobManager.new
    assert_equal false, jm.nil?
    assert_equal false, jm.exec_state
    
    job = generic_job "TEST_STOPPED_MANAGER_JOB", "Happy Input"
    result = jm.submit_job(job)
    assert_equal false, result
    
  end
  
  
  def test_job_manager_get_next_job_from_stopped_manager
    set_test_step_name "test_job_manager_submit_to_stop_manager"
    
    jm = JM::JobManager.new
    assert_equal false, jm.nil?
    assert_equal false, jm.exec_state
    
    result = nil
    assert_raises Timeout::Error do 
      Timeout::timeout(5) {result = jm.get_next_job}
    end
      
    assert_equal nil, result
    
  end
  
  
  def test_job_manager_get_next_job_
    set_test_step_name "test_job_manager_submit_to_stop_manager"
    
    # Start Job Manager with No Workers
    jm = JM::JobManager.new 
    jm.start 0
    assert_equal false, jm.nil?
    assert_equal true, jm.exec_state
    assert_equal 0, jm.queued_jobs
    assert_equal 0, jm.worker_count
    
    # Submit single job.
    job = generic_job "TEST_GET_NEXT_JOB", "Happy Input"
    result = jm.submit_job(job)
    assert_equal true, result
    assert_equal 1, jm.queued_jobs
    
    # Get Next Job should return immediatly
    result = nil
    Timeout::timeout(5) {result = jm.get_next_job}
    
    assert_equal 0, jm.queued_jobs
      
    assert_equal job, result
    
  end
  
    
    
end