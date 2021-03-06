Gem::Specification.new do |s|

s.name        = 'job_manager'
  s.version     = '0.0.1'
  s.date        = '2017-05-05'
  s.summary     = "Thread pool manager"
  s.description = "Create jobs and submit to them to a managed thread pool"
  s.authors     = ["Scott Jackson"]
  s.email       = 'scott.jackson.swe@gmail.com'
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'
  
  s.homepage    = "https://github.com/AgileTrossDev/job_manager"
  
  s.license       = 'MIT'


end
