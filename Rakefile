# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:lint)
rescue LoadError
  desc "Run RuboCop (install the rubocop gem first)"
  task :lint do
    abort "RuboCop is not available. Run `bundle install`."
  end
end

# Maintainer-only: re-download the four jconj conjugation tables (conj.csv,
# conjo.csv, conotes.csv, kwpos.csv) from upstream into lib/daidai/resources/.
# These tab-separated tables hold all of Daidai's linguistic knowledge and are
# shipped inside the gem, so refresh them whenever upstream jconj changes.
namespace :daidai do
  RESOURCES = {
    "conj.csv" => "https://raw.githubusercontent.com/yamagoya/jconj/master/data/conj.csv",
    "conjo.csv" => "https://raw.githubusercontent.com/yamagoya/jconj/master/data/conjo.csv",
    "conotes.csv" => "https://raw.githubusercontent.com/yamagoya/jconj/master/data/conotes.csv",
    "kwpos.csv" => "https://raw.githubusercontent.com/yamagoya/jconj/master/data/kwpos.csv"
  }.freeze
  RESOURCES_DIR = "lib/daidai/resources"

  desc "Sync the bundled jconj conjugation tables from upstream"
  task :sync_resources do
    require "fileutils"

    FileUtils.mkdir_p(RESOURCES_DIR)
    RESOURCES.each do |file, url|
      dest = File.join(RESOURCES_DIR, file)
      sh "curl", "-fsSL", url, "-o", dest
      puts "synced #{file}"
    end
    puts "Done. Review the diff before committing."
  end

  desc "Alias for daidai:sync_resources"
  task sync: :sync_resources

  desc "Fail if the bundled jconj tables have drifted from upstream"
  task :check_resources do
    Rake::Task["daidai:sync_resources"].invoke
    out = `git status --porcelain #{RESOURCES_DIR}`
    if out.empty?
      puts "Bundled resources match upstream jconj — clean."
    else
      puts "Bundled resources are stale relative to upstream jconj:"
      puts out
      abort "Run `rake daidai:sync_resources` and commit the diff."
    end
  end
end

task default: %i[lint test]
