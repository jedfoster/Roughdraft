require 'yaml'
require 'gemoji'

load 'tasks/emoji.rake'

desc "Run the app's server in either development or production mode"
task :server do
  environment = 'development'

  if ARGV.last.match(/(development|production)/)
    environment = ARGV.last
  end

  puts "Starting App in #{environment.upcase} mode..."

  exec "bundle exec rackup config.ru -p 3000 -E #{environment}"

  task environment.to_sym do ; end
end

