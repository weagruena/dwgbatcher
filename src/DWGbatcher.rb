# DWGbatcher
#!/usr/bin/env ruby
#
require 'yaml'
require "win32ole"
require "fileutils"

# Exit while compiling
exit if Object.const_defined?(:Ocra)

#~ # Configuration
def config()
	cfile = 'DWGbatcher.ini'
	if File.exists?(cfile)
		@cfg = YAML.load_file(cfile)
		# Settings
		@acad = @cfg['settings']['acad']
		@script = @cfg['settings']['script']
		@del_bak = @cfg['settings']['del_bak']	
		@show_script = @cfg['settings']['show_script']
		@start = @cfg['commands']['start']		
		@cmds = @cfg['commands']['cmds']
		@end = @cfg['commands']['end']				
	else
		puts 'Error loading file ' + cfile
	end
end

config()
if ARGV.length != 1
	
	#~ # Select drawings (DWG) folder
	shell = WIN32OLE.new("Shell.Application")
	folder = shell.BrowseForFolder(0,"Select folder with drawings (*.DWG)",1)
	shell = nil
	if folder.self.path == nil
		puts "Folder is missing."
		exit
	else
		dir = folder.self.path
	end

else
	
	#~ # Start with folder (first argument)
	dir = ARGV[0]
	if !File.exists?(dir)
		puts "Folder is missing."
		exit
	end
	
end


File.open(@script, "w+") do |f|
	f.puts ";* Folder:\n;#{dir}\n"
	Dir.chdir(dir)
	#~ # Collect DWG's
	dwgs = Dir.glob("*.dwg")
	f.puts ";* #{dwgs.length} Drawings (DWG):"
	f.puts ";Start script\n"
	@start.each { |s| f.puts s }
	dwgs.sort.each do |dwg|
		@cmds.each do |cmd|
			if cmd != "*dwg*"
				f.puts cmd
			else
				f.puts dwg
			end
		end	
	end
	@end.each { |e| f.puts e }
	f.puts "\n;End script"
end

#~ # Start AUTOCAD
system("notepad #{@script}") if @show_script == 1
system("#{@acad} /b #{@script}")

#~ # Delete BAK
if @del_bak == 1
	Dir.glob("*.bak").each { |bak| File.delete(bak) }
end
