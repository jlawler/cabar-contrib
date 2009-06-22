require 'yaml'
class Runsv
  Valid=[:start,:stop,:try,:kill,:up,:down].freeze unless defined?(Valid)
  Aliases={
    :start => :up,
    :stop => :down,
    :once => :try
  }.freeze unless defined?(Aliases)
  TimeSizes={
    :days => 3600*24,
    :hours => 3600,
    :minutes => 60
  }.freeze unless defined?(TimeSizes)
  attr_accessor :base_path
  def initialize base_pathi
    self.base_path=base_pathi
  end
  def command cmd
    STDERR.puts "COMMANDING #{cmd} TO #{control_path}"
    letter=(Aliases[cmd]||cmd).to_s.split(//).first
    return unless File.exists?(control_path)
    File.open(control_path,'w'){|fh| fh.print letter}
  end
  def exists?
    File.exists?(stat_path) and File.exists?(control_path)
  end
  def permissions?
    File.readable?(stat_path) and File.writable?(control_path)
  end
  def read?
    File.readable?(stat_path)
  end
  def write?
    File.writable?(control_path)
  end
  def stat_path
    "#{self.base_path}/supervise/stat"
  end
  def control_path
    "#{self.base_path}/supervise/control"
  end
  def last_changed_ary
    seconds_old=Time.now-File.mtime(stat_path)
    ret={}
    TimeSizes.keys.sort{|a,b|TimeSizes[a] <=> TimeSizes[b]}.each do |window|
      if seconds_old  > TimeSizes[window]
        ret[window]=seconds_old.to_i/TimeSizes[window]
        seconds_old-=(TimeSizes[window]*ret[window])
      end
    end
    ret[:seconds]=seconds_old
    STDERR.puts ret.inspect
    ret
  end
  def status
    return nil unless File.exists?(stat_path)
    temp=File.read(stat_path).gsub(/\n/,'')
    return temp unless temp=~/(\S+), got (\S)\S+, want (\S+)/
    return "#{$1} (want #{$3})" 
  end
end
=begin
module Runsv
  SEC_PER_DAY=3600*24 unless defined? SEC_PER_DAY
  class <<self
  def list_services
    return @first_pass if @first_pass
    first_pass=Dir.new(sv_path).select{|s| s if is_service?(s)}
    @first_pass=first_pass.inject({}){|tot,s|
      this={}
      this[:seconds_old]=seconds_old=Time.now-
        (File.mtime(sv_stat_path(s))>File.mtime(sv_pid_path(s)) ? File.mtime(sv_stat_path(s)): File.mtime(sv_pid_path(s)))
      time=""
      if seconds_old > SEC_PER_DAY
        time << sprintf("%02id:",(seconds_old/SEC_PER_DAY)) 
        seconds_old-=(seconds_old.to_i/SEC_PER_DAY)*SEC_PER_DAY
      end
      if seconds_old > 3600
        time << sprintf("%02ih:",(seconds_old/3600)) 
        seconds_old=seconds_old-(seconds_old.to_i/3600)*3600
      end
      time << sprintf("%02im:%02is",(seconds_old/60),(seconds_old%60))
      this[:service]="#{s}" 
      this[:status]=(sv_status(s))
      this[:formatted_time]=  time
      tot[s]=this
      tot
    }
  end
  def filtered_services
    s=list_services
    CnuRake::Services.autorun.each{|service|
      unless s[service]
        s[service]={:status => 'down'}
      end
    }
    s.reject!{|k,v|
       !(Services.autorun.include?(k)) and 
        v and v[:status]=='down' and
        v[:seconds_old] and v[:seconds_old]>300 
    }
    s.each{|k,v|
       v[:service]=k unless v[:service]
       if !(Services.autorun.include?(k)) and 
        v and v[:status]=='down' and
        v[:seconds_old] and v[:seconds_old]<300 
        v[:rogue]=true
       end
    }
    s
  end
  def is_service?(s)
    return false if (s=='.' or s=='..')
    return false unless File.exists? sv_control_path(s)
    path=sv_path(s)
    spath="#{path}/supervise"
    File.directory?(path) and 
      File.exists?(spath) and  
      File.directory?(spath)
  end
  def sv_path(s=nil)
    path=ENV['RUNSV_DIR'] || '/var/service'
    return path if s.nil?
    "#{path}/#{s}"
  end
  def sv_stat_path(s)
    "#{sv_path(s)}/supervise/stat"
  end
  def sv_pid_path(s)
    "#{sv_path(s)}/supervise/stat"
  end

  def sv_control_path(s)
    "#{sv_path(s)}/supervise/control"
  end

  def sv_status(s)
    return nil unless is_service?(s)
    temp=File.read(sv_stat_path(s)).gsub(/\n/,'')
    return temp unless temp=~/(\S+), got (\S)\S+, want (\S+)/
    return "#{$1} (want #{$3})" 
  end
  def sv_control(s,command)
    return nil unless is_service?(s)
    File.open(sv_control_path(s),'w'){|fh| fh.print command}
  end
  def sv_try(s)
    sv_control(s,'o')
  end
  def sv_up(s)
    sv_control(s,'u')
  end
  def sv_down(s)
    sv_control(s,'d')
  end
  def sv_sighup(s)
    sv_control(s,'h')
  end
  def sv_sigkill(s)
    sv_control(s,'k')
  end
  def build_individual
    list_services.keys.select{|s|
    eval "
      task \"#{s}_start\".to_sym do 
         sv_up('#{s}') 
      end
      task \"#{s}_stop\".to_sym do 
        sv_down('#{s}') 
      end
      task \"#{s}_status\".to_sym do 
        sv_status('#{s}') 
      end
    " 
  }
  end
  end
end
=end
