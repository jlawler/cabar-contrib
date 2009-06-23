class FinishHook
  attr_accessor :blk, :name, :auto
  @@hooks={}
  def self.call(facet)
     self.each{|h|h.blk.call(facet)}
  end
  def self.each 
    @@hooks.values.each{|a|yield(a)}
  end
  def self.add_hook(name, &blk)
    @@hooks[name.to_sym]=blk
  end
  def [] hook_name
    @@hooks[hook_name.to_sym]
  end
end
class StartHook
  attr_accessor :blk, :name, :auto
  @@hooks={}
  def self.call(facet)
     self.each{|h|
h.blk.call(facet)}
  end
  def self.each 
    @@hooks.values.each{|a|yield(a)}
  end
  def self.add_hook(name, &blk)
    new_hook=self.new
    new_hook.name=name
    new_hook.blk=blk
    @@hooks[name.to_sym]=new_hook
  end
  def [] hook_name
    @@hooks[hook_name.to_sym]
  end
end
Dir.glob("#{File.dirname(__FILE__)}/hooks/*.rb"){|h|
  STDERR.puts h.inspect
  require h
}
