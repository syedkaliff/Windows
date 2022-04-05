terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
   #   version = "4.8.0"
        }
}

  
  
    
  backend "s3" {
    bucket = "tfs3-syed"
    key    = "states/windows1.tfstate"
    region = "us-west-1"
    dynamodb_table = "tfs3-syed"
  }

      
      
    }

provider "aws" {
  region = "us-west-1"
}

