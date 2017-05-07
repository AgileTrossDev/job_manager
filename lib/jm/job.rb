


module JM
    class Job
    attr_accessor :name, :state, :exception, :time_out, :input
      def initialize action, input =nil,  handlers = {}, name = "undefined_job", time_out=10, start_after = nil
          @action = action
          @handlers = {:default => (lambda { |x| self.default_handler(x) })}
          @handlers = @handlers.merge(handlers)
          @start_after = start_after
          @input = input
          @time_out = time_out
          
          @name = name
          @state = "pending"
          @exception = nil 
          puts "Job Created: #{name}"
      end
      
      def execute input =nil
          @state = "started"
          @input = input unless input.nil?
          begin
            @state = @action.call(@input)
             puts "Job #{@name} action complete."
          rescue => e
            puts "Job #{@name} encountered exception during execution. Explanation: #{e.message}"
            @state = "exception"
          end
          @state
      end
      
      def call_handler(handle, input=nil)
        result =false
         if  @handlers[handle].nil?
             puts "Using default handler because no handler was defined for #{handle} - #{input}"
             result = default_handler input
         else
           result = @handlers[handle].call(input)
         end
      end
      
      def default_handler x
       puts "#{@name} default handler for input: #{x}"
       true
      end
    end
end