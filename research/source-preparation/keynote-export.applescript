-- Throwaway. Usage: osascript keynote-export.applescript <in.pptx> <out.pdf>
-- Untested end to end: the Automation consent prompt could not be answered (screen locked).
-- Keynote is sandboxed; create <out.pdf> first so the sender can issue a sandbox extension for it.
on run argv
	set src to POSIX file (item 1 of argv)
	set dst to POSIX file (item 2 of argv)
	with timeout of 600 seconds
		tell application "Keynote"
			set d to open src
			export d to dst as PDF with properties {export style:IndividualSlides, all stages:false, skipped slides:true, slide numbers:false, date:false, PDF image quality:Better}
			set n to count of slides of d
			close d saving no
		end tell
	end timeout
	return (n as text)
end run
