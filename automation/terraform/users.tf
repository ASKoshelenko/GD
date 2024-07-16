# Read list of users from file
data "local_file" "usernames" {
  filename = "${path.module}/../../users.txt"
}
# Read list of emails from file
data "local_file" "emails" {
  filename = "${path.module}/../../emails.txt"
}
data "local_file" "userid" {
  filename = "${path.module}/../../userid.txt"
}

 # Import usernames from users
locals {
  read_usernames = split( "\n", data.local_file.usernames.content)
  read = split( "\n", data.local_file.emails.content)
  read_userid = split( "\n", data.local_file.userid.content)
    emails = [
        for email in local.read:
          email
          if email != ""
    ]
  usernames = [
    for username in local.read_usernames:
      username
      if username != ""
  ]
  userid = [
      for category in local.read_userid:
          category
          if category != ""
  ]
}