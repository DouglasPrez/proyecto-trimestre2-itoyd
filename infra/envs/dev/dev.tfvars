environment        = "dev"
project_name       = "proyecto-trimestre2"
region             = "us-east-1"
bucket_name        = "proyecto-trimestre2-v2-bucket"
lambda_memory_size = 128
lambda_timeout     = 30

# D3 — dominio sub-delegado por los instructores
domain_name       = "grupo2.oyd.solid.com.gt"
health_check_path = "/"
api_stage_name    = "dev"

# D4 — Async module
async_visibility_timeout_seconds    = 30
async_message_retention_seconds     = 345600
async_max_receive_count             = 5
async_dlq_message_retention_seconds = 1209600

# D4 — Event source mapping
event_batch_size                         = 10
event_maximum_batching_window_in_seconds = 5
event_bisect_batch_on_function_error     = false

# D4 — Scheduler
scheduler_schedule_expression = "cron(0 6 * * ? *)"
scheduler_timezone            = "America/Guatemala"

# D4 — Async consumer
async_consumer_name        = "async-consumer"
async_consumer_memory_size = 128
async_consumer_timeout     = 60
