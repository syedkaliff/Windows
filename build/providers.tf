terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.8.0"
        }
}

  
  
    
  backend "s3" {
    bucket = "tfs3-syed"
    key    = "states/windows.tf"
    region = "us-west-1"
  }

      
      
    }

provider "aws" {
  region = "us-west-1"
}

