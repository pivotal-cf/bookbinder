Dir.glob('tasks/*.rake').each { |r| import r }

task :default => ["spec:unit", "jasmine:ci"]
require 'jasmine'
load 'jasmine/tasks/jasmine.rake'
