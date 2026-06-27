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

# Maintainer-only: re-download the four JMdictDB conjugation tables (conj.csv,
# conjo.csv, conotes.csv, kwpos.csv) from upstream into lib/daidai/resources/.
# These tab-separated tables hold all of Daidai's linguistic knowledge and are
# shipped inside the gem, so refresh them whenever upstream JMdictDB changes.
namespace :daidai do
  JMDICTDB = "https://gitlab.com/yamagoya/jmdictdb/-/raw/master/jmdictdb/data"
  RESOURCES = {
    "conj.csv" => "#{JMDICTDB}/conj.csv",
    "conjo.csv" => "#{JMDICTDB}/conjo.csv",
    "conotes.csv" => "#{JMDICTDB}/conotes.csv",
    "kwpos.csv" => "#{JMDICTDB}/kwpos.csv"
  }.freeze
  RESOURCES_DIR = "lib/daidai/resources"

  desc "Sync the bundled JMdictDB conjugation tables from upstream"
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

  desc "Fail if the bundled JMdictDB tables have drifted from upstream"
  task :check_resources do
    Rake::Task["daidai:sync_resources"].invoke
    out = `git status --porcelain #{RESOURCES_DIR}`
    if out.empty?
      puts "Bundled resources match upstream JMdictDB — clean."
    else
      puts "Bundled resources are stale relative to upstream JMdictDB:"
      puts out
      abort "Run `rake daidai:sync_resources` and commit the diff."
    end
  end
end

load File.expand_path("lib/daidai/release.rake", __dir__)

task default: %i[lint test]

# Sign off only after the checks pass: lint + test are prerequisites, so rake
# aborts before the signoff body runs if either fails. This makes "green, then
# sign off" the one easy path (raw `gh signoff -f` still bypasses it — gh-signoff
# is trust-based). `-f` is needed because jj leaves git's HEAD detached.
desc "Run lint + tests, then sign off the commit via gh-signoff (only if they pass)"
task signoff: %i[lint test] do
  sh "gh signoff create -f"
end
