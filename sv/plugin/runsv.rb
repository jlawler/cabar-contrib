require 'yaml'
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

