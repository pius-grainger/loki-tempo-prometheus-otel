# For demo: using local backend. Switch to S3 for real environments
# by running ./scripts/bootstrap-state.sh first, then uncommenting below.
#
# terraform {
#   backend "s3" {
#     bucket         = "<ACCOUNT_ID>-terraform-state"  # Replace with output from bootstrap-state.sh
#     key            = "observability/staging/terraform.tfstate"
#     region         = "eu-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
