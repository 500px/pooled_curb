require "./lib/version"

Gem::Specification.new do |s|
  s.name        = "pooled_curb"
  s.version     = PooledCurb::VERSION
  s.date        = "2014-10-24"
  s.summary     = "Pooled curb"
  s.description = "Simple wrapper around curb to provide a pool of reusable connections"
  s.authors     = ['Arseniy Ivanov', 'Chris Micacchi', 'Vova Drizhepolov']
  s.email       = ["arseniy@500px.com", "chris@500px.com", "vova@500px.com"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.homepage = "https://github.com/500px/pooled-curb"
  s.license = "MIT"

  s.add_dependency "activesupport", "~> 4.1"
  s.add_dependency "yajl-ruby", "~> 1.2"
  s.add_dependency "curb", "~> 0.8"
  s.add_dependency "connection_pool", "~> 2.0"

  s.add_development_dependency "json", "~> 1.8"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency 'rake', "~> 10.1"
end
