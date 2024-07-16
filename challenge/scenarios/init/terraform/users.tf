# Read list of user id from file
data "local_file" "users" {
  filename = "${path.module}/../../users.csv"
}

locals {
  csv_data = data.local_file.users.content 
  users_draft = csvdecode(local.csv_data)

  users_fine = {
    for user in local.users_draft :
    "fine" => {
      "userid"   = replace(lower(user["username"]), " ", "_"),
      "username" = title(user["username"]),
      "email"    = lower(user["email"]),
      "category" = user["category"]
    }...
  }

  users = local.users_fine["fine"]

}