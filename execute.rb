$stdout.sync = true
require "faraday"

changed_files = ENV.fetch("CHANGED_FILES").split(' ')
reportable_files = []

changed_files.each do |file|
  if file.match(/.+\.jpe?g\z/i)
    puts "Compressing #{file}"
    size_before = File.stat(file).size
    system "mozjpeg -copy none -optimize -outfile #{file} #{file}"
    size_after = File.stat(file).size
    size_diff = size_before-size_after
    percentage_change = (1-(size_after.to_f/size_before))*100

    # check how much was saved, if its negligable then that's probably not a change worth making as it will only reduce quality with little benefit.
    if percentage_change < 1
      system "git checkout #{file}" 
    else
      # record discovery
      reportable_files << file
    end
  else
    puts "Skipping #{file}"
  end
end

message = "Optimized image assets"
branch = "pushbit/smusher"
if changed_files.length > 0
  branch += "-#{ENV.fetch('GITHUB_NUMBER')}"
end

puts "Checking out branch"
system "git checkout -B #{branch}"

puts "Adding updated files"
system "git add #{reportable_files.join(" ")}"

puts "Commiting changed files"
system "git commit -m \"#{message}\""

puts "Pushing branch"
system "git push -f origin #{branch}"