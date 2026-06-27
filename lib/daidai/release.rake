# frozen_string_literal: true

namespace :release do
  desc "Bump version. Usage: rake release:bump[1.2.3]"
  task :bump, [ :version ] do |_t, args|
    version = args[:version]
    abort "Usage: rake release:bump[1.2.3]" unless version&.match?(/\A\d+\.\d+\.\d+\z/)

    version_file = File.expand_path("version.rb", __dir__)
    content = File.read(version_file)
    File.write(version_file, content.sub(/VERSION = ".*"/, %(VERSION = "#{version}")))
    puts "Updated #{version_file}"

    puts "\nVersion bumped to #{version}"
    puts "Next steps:"
    puts "  jj describe -m 'Bump version to #{version}'"
    puts "  jj git push"
    puts "  git tag v#{version} && git push origin v#{version}   # triggers the Release workflow"
  end
end

desc "Build the gem"
task :build do
  sh "gem build daidai.gemspec"
end

desc "Build and push the gem to RubyGems"
task release: :build do
  gemfile = Dir["daidai-*.gem"].max_by { |f| File.mtime(f) }
  abort "No .gem file found" unless gemfile
  sh "gem push #{gemfile}"
end
