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
    return unless File.exists?(control_path) and self.write?
    letter=(Aliases[cmd]||cmd).to_s.split(//).first
    File.open(control_path,'w'){|fh| fh.print letter}
  end
  def exists?
    File.exists?(stat_path) and File.exists?(control_path)
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
  def last_changed_hsh
    seconds_old=Time.now-File.mtime(stat_path)
    ret={}
    TimeSizes.keys.sort{|a,b|TimeSizes[a] <=> TimeSizes[b]}.each do |window|
      if seconds_old  > TimeSizes[window]
        ret[window]=seconds_old.to_i/TimeSizes[window]
        seconds_old-=(TimeSizes[window]*ret[window])
      end
    end
    ret[:seconds]=seconds_old
    ret
  end
  def last_changed_string
    hsh=last_changed_hsh
    ret = []
    ret << "%02id"%hsh[:days] if hsh[:days] or ret.size > 0 
    ret << "%02ih"%hsh[:hours] if hsh[:hours] or ret.size > 0
    ret << "%02im"%hsh[:minutes] if hsh[:minutes] or ret.size > 0
    ret << "%02is"%hsh[:seconds] if hsh[:seconds] or ret.size > 0
    ret.join(':') 
  end
  def status
    return nil unless File.exists?(stat_path)
    temp=File.read(stat_path).gsub(/\n/,'')
    return temp unless temp=~/(\S+), got (\S)\S+, want (\S+)/
    return "#{$1} (want #{$3})" 
  end
end
