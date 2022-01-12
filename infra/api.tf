data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "app.js.zip"
  source_file = "../app/app.js"
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = var.api_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  inline_policy {
    name = var.api_name

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "S3",
          "Effect" : "Allow",
          "Action" : [
            "s3:*"
          ],
          "Resource" : [
            "${aws_s3_bucket.data.arn}",
            "${aws_s3_bucket.data.arn}/*"
          ]
        }
      ]
    })
  }
}


resource "aws_iam_role_policy_attachment" "attach_lambda_basic_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.api_name}"
  retention_in_days = 1
}


resource "aws_lambda_function" "function" {
  description      = "Function Managed by Terraform"
  filename         = "app.js.zip"
  function_name    = var.api_name
  handler          = "app.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = true
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "nodejs14.x"
  depends_on = [
    aws_iam_role_policy_attachment.attach_lambda_basic_policy,
    aws_iam_role_policy_attachment.attach_ssm_read_policy,
    aws_cloudwatch_log_group.log_group,
  ]
  environment {
    variables = {
      S3_DATA_BUCKET = aws_s3_bucket.data.id
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Managed by Terraform"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy_root,
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_root,
    aws_api_gateway_integration.lambda
  ]
}



resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}


resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_stage.stage.invoke_url
}

## If you manage your DNS with Route53 with AWS, then a CNAME record can also be created. Pls refer - 
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record 
