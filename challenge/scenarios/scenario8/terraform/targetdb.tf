data "local_file" "targetdb" {
  filename = "${path.module}/../assets/targetdb.csv"
}

# Import usernames from users
locals {
  csv_secretdata = data.local_file.targetdb.content
  targetdb_data = csvdecode(local.csv_secretdata)
}
