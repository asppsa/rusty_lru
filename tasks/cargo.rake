namespace :cargo do
  desc 'Cargo build'
  task :build do
    sh 'cargo build --release'
  end

  desc 'Cargo test'
  task :test do
    sh 'cargo test'
  end
end
