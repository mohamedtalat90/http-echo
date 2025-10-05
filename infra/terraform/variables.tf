variable "argocd_namespace" {
  type    = string
  default = "argocd"
}
variable "app_namespace" {
  type    = string
  default = "http-echo"
}
variable "git_repo_url" {
  type        = string
  description = "https://github.com/mohamedtalat90/http-echo"
}
variable "git_revision" {
  type    = string
  default = "main"
}
