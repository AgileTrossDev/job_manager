require "jm/job_manager.rb"
require "jm/job.rb"

module TEST
    def initialize args
       super args    
        #@test_suite = nil
    end
    
    
    #### ACTIONS ####
    
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
    
    
    def generic_exception_action        
       lambda {|x|
           t = rand(1..10)
           puts "Sleeping (#{t}) then raising a generic exception."           
           sleep(t)
           raise "generic exception action triggered: #{x}"
           true
        } 
    end
    
    
    ##### Handlers ####
    def generic_handler
       lambda {|x| puts "generic handler called: #{x}";true} 
    end
    
    #def generic_handler_input      
    #   {:test => generic_handler}
    #end
    
    
    #### Jobs ####
    def generic_job name = @test_name, input =nil
        obj = JM::Job.new((generic_action), input, nil, name )
        obj
    end
    
    def sleepy_job name = @test_name, input =nil
      obj = JM::Job.new((sleepy_action), input, nil, name,11 )
      obj
    end
    
    
    
    def generic_exception_job name = @test_name, input =nil
      # NOTE: By default this job has handler turned off.
      obj = JM::Job.new((generic_exception_action), input, nil, name,11 )
      obj
    end
    
    
    #### Helpful Test Stuff ####
    
    def set_test_step_name name 
        @test_name = name
        puts "\n\n#{@test_suite} Test: #{@test_name} started\n\n"        
    end
    
    def common_teardown
        puts "\n\n#{@test_suite} Test: #{@test_name} ended\n\n" 
    end

end
