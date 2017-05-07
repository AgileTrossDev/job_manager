require "jm/job_manager.rb"
require "jm/job.rb"

module TEST
    def initialize args
       super args    
        @test_suite = nil
    end
    
    def generic_action
       lambda {|x| puts "generic action called: #{x}";true} 
    end
    
    def sleepy_action
       lambda {|x|
           t = rand(1..10)
           puts "sleepy action(#{t}) called: #{x}"
           sleep(t);
           true
        } 
    end
    
    def generic_handler
       lambda {|x| puts "generic handler called: #{x}";true} 
    end
    
    def generic_handler_input
      
       {:test => generic_handler}
    end
    
    def generic_job name = @test_name, input =nil
        obj = JM::Job.new((generic_action), input, {}, name )
        obj
    end
    
    def sleepy_job name = @test_name, input =nil
        obj = JM::Job.new((sleepy_action), input, {}, name,11 )
        obj
    end
    
    def set_test_step_name name 
        @test_name = name
        puts "\n\n#{@test_suite} Test: #{@test_name} started\n\n"
        
    end
    
    def common_teardown
        puts "\n\n#{@test_suite} Test: #{@test_name} ended\n\n" 
    end

end
