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
      puts "#{file} optimization not enough to report"
      system "git checkout #{file}" 
    else
      # record discovery
      reportable_files << file
    end
  else
    puts "Skipping #{file}"
  end
end

branch = "pushbit/smusher"
if changed_files.length > 0
  branch += "-#{ENV.fetch('GITHUB_NUMBER')}"
end

if reportable_files.length > 0
  puts "Checking out branch"
  system "git checkout -B #{branch}"

  puts "Adding updated files"
  system "git add #{reportable_files.join(" ")}"

  puts "Commiting changed files"
  system "git commit -m \"Optimized image assets\""

  puts "Pushing branch"
  system "git push -f origin #{branch}"
  
  conn = Faraday.new(:url => ENV.fetch("APP_URL")) do |config|
    config.adapter Faraday.default_adapter
  end
  
  reportable_files.each do |file|
    discovery = {
      title: "#{file} optimized",
      task_id: ENV.fetch("TASK_ID"),
      kind: :optimization,
      identifier: ["smusher", file, ENV.fetch("BASE_BRANCH")].join("-"),
      branch: branch,
      code_changed: true,
      priority: :low,
      message: discovery_message
    }

    puts "Posting discovery"
    res = conn.post do |req|
      req.url '/discoveries'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Basic #{ENV.fetch("ACCESS_TOKEN")}"
      req.body = discovery.to_json
    end
  end
else
  puts "No images were optimized"
end