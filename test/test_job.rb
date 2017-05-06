require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job.rb"
require "helper"

class TestJob < Minitest::Test
  def test_job_create
    action = generic_action
    test = JM::Job.new(action, {}, "test_job_create" )
    
    assert_equal false, test.nil?
  end
  
  def test_job_action
    action = generic_action
    test = JM::Job.new(action, {}, "test_job_action" )
    result = test.execute"test_job_action"
    assert_equal true, result
  end
  
  def test_job_handler
      
    action = generic_action
    handlers = {:test => generic_handler}
    test = JM::Job.new(action, handlers, "test_job_handler" )
    
    result = test.execute"test_job_handler"
    assert_equal true, result
    
    result = test.call_handler(:test, "test_job_handler--->CALLED!!!")
    assert_equal true, result
  end
  
  def test_job_default_handler
      
    action = generic_action
    handlers = {:test => generic_handler}
    test = JM::Job.new(action, handlers, "test_job_default_handler" )
    
    result = test.execute"test_job_handler"
    assert_equal true, result
    
    result = test.call_handler(:default, "test_job_default_handler--->Sounds Good!!!")
    assert_equal true, result
  end
  
  def test_job_undefined_handler
      
    action = generic_action
    handlers = {:test => generic_handler}
    test = JM::Job.new(action, handlers, "test_job_undefined_handler" )
    
    result = test.execute"test_job_undefined_handler"
    assert_equal true, result
    
    result = test.call_handler(:undefined, "test_job_undefined_handler--->Sounds Good!!!")
    assert_equal true, result
   
  end
    
    
end