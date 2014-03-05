set :stages, %w(production staging)     #various environments
load "deploy/assets"                    #precompile all the css, js and images... before deployment..
require "bundler/capistrano"            # install all the new missing plugins...
require 'capistrano/ext/multistage'     # deploy on all the servers..
require "rvm/capistrano"                # if you are using rvm on your server..
require './config/boot'
#require 'delayed/recipes'               # load this for delayed job..
#require "whenever/capistrano"

before "deploy:assets:precompile","deploy:config_symlink"
#before "deploy:update_code",    "delayed_job:stop"  # stop the previous deployed job workers...
after "deploy:update", "deploy:cleanup" #clean up temp files etc.
after "deploy:update_code","deploy:migrate"
after "deploy:create_symlink", "deploy:update_crontab"
#after "deploy:start",   "delayed_job:start" #start the delayed job
#after "deploy:restart", "delayed_job:restart" # restart it..

#set :whenever_command, "bundle exec whenever"
set(:application) { "unicorn_app" }
#set :delayed_job_args, "-n 2"            # number of delayed job workers
set :rvm_ruby_string, '2.0.0'             # ruby version you are using...
set :rvm_type, :user
#set :whenever_environment, defer { stage }  # whenever gem for cron jobs...
#set :whenever_identifier, defer { "#{application}_#{stage}" }
server "ec2-54-235-63-23.compute-1.amazonaws.com", :web, :app, :db, primary: true
set (:deploy_to) { "/home/ec2-user/#{application}/#{stage}" }
set :user, 'ec2-user'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:auth_methods] = ["publickey"]
ssh_options[:keys] = ["/home/ashish/Desktop/nqlivedev.pem"]

set :keep_releases, 3
set :repository, "git@bitbucket.org:ashish198907/unicorn_app.git"
set :use_sudo, false
set :scm, :git
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :git_enable_submodules, 1

#namespace :deploy do
#  task :start do ; end
#  task :stop do ; end
#  task :restart, :roles => :app, :except => { :no_release => true } do
#    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#  end
#  task :config_symlink do
#    run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
#  end
#end

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}_#{fetch(:stage)}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}_#{fetch(:stage)}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end



#set :stages, %w(production staging)     #various environments
#
#require "bundler/capistrano"
#require 'capistrano/ext/multistage'
#require "rvm/capistrano"
#require './config/boot'
#server "ec2-54-235-63-23.compute-1.amazonaws.com", :web, :app, :db, primary: true
#
#default_run_options[:pty] = true
#ssh_options[:forward_agent] = true
#ssh_options[:auth_methods] = ["publickey"]
#ssh_options[:keys] = ["/home/ashish/Desktop/nqlivedev.pem"]
#
#set :application, "unicorn_app"
#set :user, "ec2-user"
#set :port, 22
#set :deploy_to, "/home/#{user}/#{application}/#{fetch(:stage)}"
#set :deploy_via, :remote_cache
#set :use_sudo, false
#
#set :scm, "git"
#set :repository, "git@github.com:ashish198907/#{application}.git"
#set :branch, "master"
#
#
#default_run_options[:pty] = true
#ssh_options[:forward_agent] = true
#
#after "deploy", "deploy:cleanup" # keep only the last 5 releases
#
#namespace :deploy do
#  %w[start stop restart].each do |command|
#    desc "#{command} unicorn server"
#    task command, roles: :app, except: {no_release: true} do
#      run "/etc/init.d/unicorn_#{application} #{command}"
#    end
#  end
#
#  task :setup_config, roles: :app do
#    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}_#{fetch(:stage)}"
#    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}_#{fetch(:stage)}"
#    run "mkdir -p #{shared_path}/config"
#    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
#    puts "Now edit the config files in #{shared_path}."
#  end
#  after "deploy:setup", "deploy:setup_config"
#
#  task :symlink_config, roles: :app do
#    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
#  end
#  after "deploy:finalize_update", "deploy:symlink_config"
#
#  desc "Make sure local git is in sync with remote."
#  task :check_revision, roles: :web do
#    unless `git rev-parse HEAD` == `git rev-parse origin/master`
#      puts "WARNING: HEAD is not the same as origin/master"
#      puts "Run `git push` to sync changes."
#      exit
#    end
#  end
#  before "deploy", "deploy:check_revision"
#end