namespace :cargo do
  task :build do
    system "cargo build --release"
  end

  task :test do
   system "cargo test"
  end
end
