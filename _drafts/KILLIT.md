aws-sdk

s3 = Aws::S3::Client.new(
  access_key_id: AWS_ACCESS_KEY_ID,
  secret_access_key: AWS_SECRET_ACCESS_KEY,
  region: 'us-west-2'
)
recording = "/mnt/c/Users/.../20071510_OU.mp3"
s3.put_object(
  bucket: BUCKET_NAME,
  body: File.open(recording, encoding: 'BINARY'),
  # body: IO.binread(recording),
  # body: File.read(recording),
  key: "recordings/#{File.basename(recording)}",
  content_type: 'audio/mpeg'
)