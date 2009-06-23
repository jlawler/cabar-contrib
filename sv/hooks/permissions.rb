me=StartHook.add_hook(:fix_permissions){|facet|
  STDERR.puts "FIX PERMISSIONS HOOK!"
  dir=facet.service_dir
  File.chmod(0750, File.join(dir,'supervise'))
  File.chmod(0770, File.join(dir,'supervise/control'))
  File.chmod(0550, File.join(dir,'supervise/stat'))
  ['supervise','supervise/control','supervise/stat'].each do|f|f=File.join(dir,f)
    new_uid,new_gid=nil,nil
    new_uid=Etc.getpwnam(facet.user).uid if facet.user
    new_gid=Etc.getgrnam(facet.group).gid if facet.group
    File.chown(new_uid,new_gid,f) if facet.group and facet.user
  end
}
