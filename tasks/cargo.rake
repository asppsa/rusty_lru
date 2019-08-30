namespace :cargo do
  task :build do
    sh "cargo build --release"
  end

  task :test do
    sh "cargo test"
  end
end
