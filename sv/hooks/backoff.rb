me=FinishHook.add_hook(:backoff){|facet|
  require 'digest/md5'
  require 'tempfile'
  next unless facet.exists? and facet.runsv.exists?
  default_opts={'reset_time' => 60, 'max_sleep' => 60, 'initial_sleep' => 2}
  opts=default_opts.merge((facet._options[:'finish-hook'] && facet._options[:'finish-hook']['backoff']) || {})
  initial_sleep=opts['initial_sleep']
  max_sleep=opts['initial_sleep']
  reset_time=opts['reset_time']
  sleep_progression=lambda{|i|i*2}
  dir=facet.service_dir
  history_file=File.join(dir,'.backoff_history')
  now=Time.now.to_i
  last_finish,window=nil,nil
  if File.exists?(history_file)
    last_finish,window=File.read(history_file).split(/,/).map{|s|s.to_i}
    if now-last_finish  < reset_time
      window=sleep_progression.call(window)
    else
      last_finish=now
      window=initial_sleep
    end
  else
    last_finish=now
    window=initial_sleep
  end 
  window=max_sleep if window > max_sleep
  begin
    File.open(history_file,'w'){|fh|fh.print([now,window].join(','))}
  rescue Exception => e
    $stderr.puts "Error writing to temp file!"
    $stderr.puts e.inspect
    $stderr.puts e.backtrace
  end
  sleep window
}
