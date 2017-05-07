require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job_manager.rb"
require "helper"

class TestJobManager < Minitest::Test
  
  include TEST
  @test_suite = "TestJobManager"
  
   
  def setup
    
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
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queue_size
      assert_equal 0, jm.worker_count
      
  end
  
  
  def test_job_manager_submit_single_job
      set_test_step_name "test_job_manager_submit_single_job"
      jm = JM::JobManager.new
      assert_equal false, jm.nil?
      
      jm.start
   
      job = generic_job "TEST_SINGLE_JOB", "Happy Input"
      jm.submit_job(job)
      assert_equal true, jm.check_monitor_status
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queue_size
      assert_equal 0, jm.worker_count
      assert_equal true, job.state
      
   
  end
  
  def test_job_manager_submit_multiple_jobsß
      set_test_step_name "test_job_manager_submit_multiple_jobs"
      jm = JM::JobManager.new
      assert_equal false, jm.nil?
      
      jm.start
      jobs = []
      1.upto(100) do |x|
        job = sleepy_job "TEST_MULTI_JOB_#{x}", "Happy Input"
        jobs.push job
        jm.submit_job(job)
      end
      
      assert_equal true, jm.check_monitor_status
      jm.stop
      
      assert_equal false, jm.check_monitor_status
      assert_equal 0, jm.queue_size
      assert_equal 0, jm.worker_count
      
      jobs.each do |job|
        assert_equal true, job.state
      end
      
   
  end
    
    
end