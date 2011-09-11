# RVM bootstrap
$:.unshift(File.expand_path("~/.rvm/lib"))
require 'rvm/capistrano'
set :rvm_ruby_string, '1.8.7-p352'
set :rvm_type, :system

# bundler bootstrap
require 'bundler/capistrano'

# main details
set :application, "sensocol.com"
role :web, "sensocol.com"
role :app, "sensocol.com"
role :db,  "sensocol.com", :primary => true

# server details
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :deploy_to, "/home/app/applications/teambox"
set :deploy_via, :remote_cache
set :user, "app"
set :use_sudo, false
set :keep_releases, "3"

# repo details
set :scm, :git
set :scm_username, "jpalley"
set :repository, "git@github.com:ecoinventions/teambox.git"
set :branch, "master"
set :git_enable_submodules, 1

# tasks
namespace :bundle do  
  desc "Run bundler, installing gems"  
  task :install do  
    #run "cd #{release_path} && bundle install --path vendor --without=development test"
    run "cd #{release_path} && bundle install --without=development test"
  end
end

namespace :deploy do
  task :start, :roles => :app do
    run "bundle exec unicorn_rails -c #{current_path}/config/unicorn.rb -D"
  end

  task :stop, :roles => :app do
    run "kill -QUIT `cat #{current_path}/tmp/pids/unicorn.pid`"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "kill -USR2 `cat #{current_path}/tmp/pids/unicorn.pid`"
  end

  desc "Symlink shared resources on each release - not used"
  task :symlink_shared, :roles => :app do
    %w{database}.each do |config|
      run "cd #{release_path} && rm -rf config/#{config}.yml && ln -sf ../../../shared/config/#{config}.yml config/"
    end
  end
end

desc "custom_setup"
task :custom_setup, :role => :app do
  %w{config}.each do |dir|
    run "cd #{deploy_to}/shared && mkdir #{dir}"
  end
end

after 'deploy:setup', :custom_setup
after 'deploy:update_code', 'deploy:symlink_shared', 'bundle:install'
after 'deploy:restart', 'deploy:cleanup'
