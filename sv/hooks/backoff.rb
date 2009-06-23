me=FinishHook.add_hook(:backoff){|facet|
  require 'digest/md5'
  require 'tempfile'
  @initial_sleep=2
  @max_sleep=60
  @reset_time=60
  @sleep_progression=lambda{|i|i*2}
  dir=facet.service_dir
  @history_file=File.join(dir,'.backoff_history')
  @now=Time.now.to_i
  if File.exists?(@history_file)
    @when,@window=File.read(@history_file).split(/,/).map{|s|s.to_i}
    if @now-@when  < @reset_time
      @window=@sleep_progression.call(@window)
    else
      @when=@now
      @window=@initial_sleep
    end
  else
    @when=@now
    @window=@initial_sleep
  end 
  @window=@max_sleep if @window > @max_sleep
  begin
    File.open(@history_file,'w'){|fh|fh.print([@now,@window].join(','))}
  rescue Exception => e
    $stderr.puts "Error writing to temp file!"
    $stderr.puts e.inspect
    $stderr.puts e.backtrace
  end
  sleep @window
}
