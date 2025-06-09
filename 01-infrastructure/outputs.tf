output "s3_data_lake_bucket_name" {
  description = "The name of the S3 bucket created for the data lake."
  value       = aws_s3_bucket.data_lake.bucket
}

output "eks_cluster_name" {
  description = "The name of the created EKS cluster."
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region where the resources are deployed."
  value       = var.aws_region
}