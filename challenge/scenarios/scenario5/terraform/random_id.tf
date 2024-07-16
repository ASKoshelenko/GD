resource "random_id" "secret_key" {
  count= length(local.users)
  byte_length = 8
}