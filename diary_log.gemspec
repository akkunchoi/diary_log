$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
# require "rakuten-ws/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "diary_log"
  s.version     = "0.0.1"
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RakutenClient."
  s.description = "TODO: Description of RakutenClient."

#  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
#  s.test_files = Dir["test/**/*"]
 
  s.add_development_dependency "rspec", ">=2.11.0"

#  s.rubyforge_project = "rakuten-ws"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

