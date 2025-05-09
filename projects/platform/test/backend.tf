terraform {
  required_version = ">= 1.10" 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
  backend "s3" {
    bucket         = "platform-test-remote-tfstate" 
    key            = "platform/test/platform-test"   
    region         = "eu-west-1"                   
    encrypt        = true                          
    use_lockfile   = true                          
  }
}

