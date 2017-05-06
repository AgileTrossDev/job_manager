
require "timeout"

module JM
    class Job
      def initialize action, handlers = {}, name = "undefined_job"
          @action = action
          @handlers = {:default => (lambda { |x| self.default_handler(x) })}
          @handlers = @handlers.merge(handlers)
          
          
          @name = name
          
          puts "Job Created: #{name}"
      end
      
      def execute input
          @action.call(input)
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