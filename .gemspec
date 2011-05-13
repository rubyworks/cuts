--- !ruby/object:Gem::Specification 
name: cuts_-_cut-based_aop_for_ruby
version: !ruby/object:Gem::Version 
  hash: 21
  prerelease: false
  segments: 
  - 1
  - 0
  - 1
  version: 1.0.1
platform: ruby
authors: 
- Thomas Sawyer
- Peter Vanbroekhoven
autorequire: 
bindir: bin
cert_chain: []

date: 2011-05-13 00:00:00 -04:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: syckle
  prerelease: false
  requirement: &id001 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 3
        segments: 
        - 0
        version: "0"
  type: :development
  version_requirements: *id001
description: Cuts is an expiremental implementation of cut-based AOP for Ruby written in pure Ruby.
email: transfire@gmail.com
executables: []

extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
- .ruby
- lib/cuts/aop.rb
- lib/cuts/cut.rb
- lib/cuts.rb
- test/test_aop.rb
- test/test_cut.rb
- HISTORY.rdoc
- LICENSE
- README.rdoc
- VERSION
- RCR.textile
has_rdoc: true
homepage: http://rubyworks.github.com/cuts
licenses: 
- Apache 2.0
post_install_message: 
rdoc_options: 
- --title
- Cuts API
- --main
- README.rdoc
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
requirements: []

rubyforge_project: cuts_-_cut-based_aop_for_ruby
rubygems_version: 1.3.7
signing_key: 
specification_version: 3
summary: Cut-based AOP for Ruby
test_files: []

