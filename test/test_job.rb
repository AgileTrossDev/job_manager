require "minitest/autorun"

#$LOAD_PATH << "lib/"
#puts $LOAD_PATH

require "jm/job.rb"
require "helper"

class TestJob < Minitest::Test
  
  include TEST
  
  def setup
    @test_suite = "TestJob"  
  end
  
  def teardown
    common_teardown
     
  end
  
  def test_job_create
    set_test_step_name "test_job_create"
    action = generic_action
    test = JM::Job.new(action,nil, nil, "test_job_create" )    
    assert_equal false, test.nil?
  end
  
  
  def test_job_action
    set_test_step_name "test_job_action"
    
    # Build Test Object
    action = generic_action
    test = JM::Job.new(action,nil, nil, "test_job_action" )
    assert_equal false, test.nil?
    
    # Execute and verify results.
    result = test.execute "test_job_action"
    assert_equal true, result
  end
  
  def test_job_handler
    set_test_step_name "test_job_handler"
    
    # Build Actions and Handlers
    action = generic_action
    handlers = generic_handler
    
    # Build Job
    test = JM::Job.new(action,nil, handlers, "test_job_handler",11)
    
    # Execute good action
    result = test.execute"test_job_handler"
    assert_equal true, result
    
    # Execute handler
    result = test.call_handler("test_job_handler--->CALLED!!!")
    assert_equal true, result
    
  end
  
  def test_job_default_handler_called_externally
    set_test_step_name "test_job_default_handler_called_externally"
    
    # Set Actions and Handlers
    action = generic_action
    handlers = generic_handler
    
    # Create Job
    test = JM::Job.new(action,nil, handlers, "test_job_default_handler_called_externally" )
    
    # Execute Job
    result = test.execute "test_job_handler"
    assert_equal true, result
    
    # Execute Default Handler, which should     
    result = test.call_handler("test_job_default_handler_called_externally--->Sounds Good!!!")
    assert_equal true, result
    
  end
  
  def test_job_undefined_handler_called_externally
    set_test_step_name "test_job_undefined_handler_called_externally"
    
    # Set Actions and Handlers
    action = generic_action
    handlers = nil
    
    test = JM::Job.new(action,nil, handlers, "test_job_undefined_handler_called_externally" )
    
    result = test.execute"test_job_undefined_handler_called_externally"
    assert_equal true, result
    
    result = test.call_handler("test_job_undefined_handler_called_externally--->Sounds Good!!!")
    assert_equal true, result
   
  end
  
  
  def test_job_generic_exception_without_handler
    set_test_step_name "test_job_generic_exception"
    
    puts "Building job..."
    test = generic_exception_job
    
    puts "Executing job..."
    result = test.execute"test_job_generic_exception"
    
    assert_equal "exception", result
  end
   
  def test_job_generic_exception_with_default_handler
    set_test_step_name "test_job_generic_exception_with_handler"
    
    puts "Building job..."
    test = generic_exception_job_with_handler
    
    puts "Executing job..."
    result = test.execute "test_job_generic_exception"
    
    assert_equal "exception", result
  end
  
  #def test_job_generic_exception_with_specilized_handler
  #  set_test_step_name "test_job_generic_exception_with_handler"
  #  
  #  #puts "Building job..."
  #  #test = generic_exception_action
  #  #
  #  #puts "Executing job..."
  #  #result = test.execute"test_job_generic_exception"
  #  #
  #  #assert_equal "exception", result
  #end
    
    
end