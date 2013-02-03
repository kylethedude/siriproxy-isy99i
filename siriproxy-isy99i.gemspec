# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-isy99i"
  s.version     = "0.0.1" 
  s.authors     = ["hoopty3", "elvisimprsntr", "kylethedude"]
  s.email       = [""]
  s.homepage    = "https://github.com/kylethedude/siriproxy-isy99i"
  s.summary     = %q{Siri Proxy ISY-99i Plugin}
  s.description = %q{This is a plugin that lets users interact with their ISY-99i through Siri. }

  s.rubyforge_project = ""

  s.files         = `git ls-files 2> /dev/null`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/* 2> /dev/null`.split("\n")
  s.executables   = `git ls-files -- bin/* 2> /dev/null`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "httparty"
end
