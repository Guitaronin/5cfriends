# unicorn -c /Users/arianryan/Sites/number_guru/local_config/unicorn_dev.rb -d -w

@application_root = File.expand_path(__FILE__ + '/../../')

# PID file for the Unicorn master
pid @application_root + '/tmp/unicorn.pid'

# This is where the application lives
working_directory @application_root

# 1 Unicorn master, 16 Unicorn workers.  The current server only has 4 cores.  Running 4 workers per core may or may not help us.
worker_processes 2

# Preload the application so forking is quicker
# preload_app true
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# Restart any workers that haven't responded in 30 seconds.  Important since we only have 16 workers and need to handle a lot of requests.
timeout 30

# Listen on a Unix data socket
# listen @application_root + '/tmp/sockets/unicorn.sock', :backlog => 2048

# Server logging
stderr_path @application_root + "/log/unicorn.stderr.log"
stdout_path @application_root + "/log/unicorn.stdout.log"

# This happens in the master before we fork off the workers.  More needs to be done here.
before_fork do |server, worker|
  # defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  
  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.

  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade.  The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  
  # Throttle the master from forking too quickly by sleeping.  Due
  # to the implementation of standard Unix signal handlers, this
  # helps (but does not completely) prevent identical, repeated signals
  # from being lost when the receiving process is busy.
  sleep 1
end