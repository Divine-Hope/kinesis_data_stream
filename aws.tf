variable "env_name" {
  description = "Environment name"
}

variable "app_name" {
  description = "Application name"
  default     = "kinesis_processor"
}

variable "s3_bucket_name" {
  description = "S3 Bucket name"
  default     = "babbel-test-divine"
}

variable "kinesis_trigger_config" {
  description = "Kinesis trigger config to invoke lambda"
  type        = map(string)
  default     = {
    batch_size    = 17000 #1M events/hour can emit 17k per minute
    max_batch_window_in_secs = 60
  }
}

data "aws_ecr_repository" "app_ecr_repo" {
  name = var.app_name
}

data "aws_kinesis_stream" "app_stream" {
  name = "babbel-test"
}

resource "aws_lambda_function" "app_function" {
  function_name = "${var.app_name}-${var.env_name}"
  timeout       = 5 # seconds
  image_uri     = "${data.aws_ecr_repository.app_ecr_repo.repository_url}:${var.env_name}"
  package_type  = "Image"

  role = aws_iam_role.app_function_role.arn

  environment {
    variables = {
      ENVIRONMENT = var.env_name
    }
  }
}

resource "aws_iam_role" "app_function_role" {
  name = "${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "s3_and_s3object_lambda" {
  name   = "s3_and_s3object_lambda-${var.env_name}"
  role   = aws_iam_role.app_function_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "s3-object-lambda:*"
        ],
        Resource = "*"
      }
    ],
  })
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name   = "cloudwatch_logs-${var.env_name}"
  role   = aws_iam_role.app_function_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:eu-north-1:058264558303:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "*"
        ]
      }
    ],
  })
}

resource "aws_iam_role_policy" "kinesis_and_logs" {
  name   = "kinesis_and_logs-${var.env_name}"
  role   = aws_iam_role.app_function_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "kinesis:SubscribeToShard",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ],
  })
}


resource "aws_s3_bucket" "app_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = data.aws_kinesis_stream.app_stream.arn
  function_name     = aws_lambda_function.app_function.arn
  starting_position = "LATEST"
  batch_size        = var.kinesis_trigger_config["batch_size"]
  maximum_batching_window_in_seconds = var.kinesis_trigger_config["max_batch_window"]
  enabled           = true
}
