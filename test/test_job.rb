require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job.rb"
require "helper"

class TestJob < Minitest::Test
  
  include TEST
  @test_suite = "TestJob"
  
  
  def setup
    
  end
  
  def teardown
    common_teardown
     
  end
  
  def test_job_create
    set_test_step_name "test_job_create"
    action = generic_action
    test = JM::Job.new(action,nil, {}, "test_job_create" )
    
    assert_equal false, test.nil?
  end
  
  def test_job_action
      set_test_step_name "test_job_action"
    action = generic_action
    test = JM::Job.new(action,nil, {}, "test_job_action" )
    result = test.execute"test_job_action"
    assert_equal true, result
  end
  
  def test_job_handler
    set_test_step_name "test_job_handler"
    action = generic_action
    handlers = generic_handler_input
    test = JM::Job.new(action,nil, handlers, "test_job_handler" )
    
    result = test.execute"test_job_handler"
    assert_equal true, result
    
    result = test.call_handler(:test, "test_job_handler--->CALLED!!!")
    assert_equal true, result
  end
  
  def test_job_default_handler
    set_test_step_name "test_job_default_handler"
    
    action = generic_action
    handlers = generic_handler_input
    test = JM::Job.new(action,nil, handlers, "test_job_default_handler" )
    
    result = test.execute"test_job_handler"
    assert_equal true, result
    
    result = test.call_handler(:default, "test_job_default_handler--->Sounds Good!!!")
    assert_equal true, result
  end
  
  def test_job_undefined_handler
    set_test_step_name "test_job_undefined_handler"
    action = generic_action
    handlers = generic_handler_input
    test = JM::Job.new(action,nil, handlers, "test_job_undefined_handler" )
    
    result = test.execute"test_job_undefined_handler"
    assert_equal true, result
    
    result = test.call_handler(:undefined, "test_job_undefined_handler--->Sounds Good!!!")
    assert_equal true, result
   
  end
    
    
end