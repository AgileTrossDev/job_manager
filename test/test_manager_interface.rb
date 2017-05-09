require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job_manager_interface.rb"
require "jm/logger.rb"
require "helper"



class TestJobManagerInterface < Minitest::Test
  include TEST
  
  def setup
    @test_suite = "TestJobManagerInterface"  
  end
  
  def teardown
    common_teardown     
  end
  
  def test_job_manager_start_stop
    set_test_step_name "test_job_manager_start_stop"
    max =3
    
    puts "Starting Job Manager"    
    JM.start(max,(JM::Logger.new))
    
    puts "Stopping Job Manager"
    JM.stop
  end
  
  def test_job_manager_start_stop_with_logger
    set_test_step_name "test_job_manager_start_stop_with_logger"
    max =3
    l = JM::Logger.new
    
    puts "Starting Job Manager"    
    JM.start(max,l)
    
    puts "Stopping Job Manager"
    JM.stop
  end

  def test_submt_job
    set_test_step_name "test_submt_job"
    job = generic_job "test_interface_submt_job", "Happy Input"
    
    JM.start 
    JM.submit_job job
    JM.stop
  end
  
  def job_manager_create
    set_test_step_name "job_manager_create"
  end
  
  def test_logger
    set_test_step_name "test_logger"
    l = JM::Logger.new
    
    JM.start 
    JM.set_logger l
    JM.stop
    
  end
  
  
  def test_manage_job
    set_test_step_name "test_manage_job"
    JM.start 
    JM.manage_job (generic_action), nil, nil, "test_manage_job"
    JM.stop
  end
    
    
end


