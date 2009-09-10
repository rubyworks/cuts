
desc "run tests"

task :test do
  $LOAD_PATH.unshift './lib'

  Dir['test/*'].each do |testfile|
    load testfile
  end
end
