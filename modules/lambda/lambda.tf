// Lambda IAM Role Definition

resource "aws_iam_role" "lambda_exec" {
    name = "lambda_execution_role"

    assume_role_policy = jsondecode({
        Version = "",
        Statement = [
            {
                Effect = "Allow",
                Principal = { Service = "lambda.amazonaws.com"},
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_logging" {
    name = "lambda_logging_policy"
    role = aws_iam_role.lambda_exec.id

    policy = jsondecode({
        Version = "",
        Statement = [
            {
                Effect = "Allow",
                Action = "logs:PutLogEvents",
                Resource = "arn:aws:logs:*:*:*"
            }
        ]
    })
}

resource "aws_lambda_function" "lambda_func" {
    function_name = ""
    role = aws_iam_role.lambda_exec.arn 
    runtime = "go1.x" // python instead
    handler = "main"
    filename = "lambda_function_payload.zip"
}
