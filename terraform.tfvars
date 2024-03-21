env_name        = "dev"
app_name        = "kinesis_processor"
s3_bucket_name  = "babbel-test-divine"
kinesis_trigger_config = {
    batch_size    = 100
    max_batch_window = 60
}