require "aws-sdk-s3"

client = Aws::S3::Client.new(
  region: ENV.fetch("S3_REGION", "auto"),
  endpoint: ENV["S3_ENDPOINT"],
  access_key_id: ENV["S3_ACCESS_KEY_ID"],
  secret_access_key: ENV["S3_SECRET_ACCESS_KEY"],
  force_path_style: true,
)

bucket = ENV["S3_BUCKET"]
max_age = 7 * 24 * 60 * 60 # 7 days in seconds
cutoff = Time.now - max_age

objects = []
client.list_objects_v2(bucket: bucket).each do |page|
  page.contents.each do |obj|
    objects << obj.key if obj.last_modified < cutoff
  end
end

if objects.empty?
  puts "No objects older than 7 days."
  exit
end

objects.each_slice(1000) do |batch|
  client.delete_objects(
    bucket: bucket,
    delete: { objects: batch.map { |key| { key: key } } },
  )
end

puts "Deleted #{objects.size} objects."
