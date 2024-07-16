provider "gitlab" {
  token = var.gitlab_token
  base_url = "http://${var.public_ip}/api/v4/"
}

resource "gitlab_project" "scenario8_projects" {
  count = length(var.userid)
  name = "${var.scenario-name}_${var.userid[count.index]}"
  auto_devops_enabled = false
  auto_cancel_pending_pipelines = "enabled"
  merge_requests_enabled = false
}

resource "gitlab_project_hook" "scenario8_projects_hook" {
  depends_on = [
    gitlab_project.scenario8_projects
  ]
  count = length(var.userid)
  project               = gitlab_project.scenario8_projects[count.index].id
  url                   = "${var.gitlab_hook}"
  push_events = true
}

resource "gitlab_user" "sc8_ro_user" {
  depends_on = [
    gitlab_project.scenario8_projects
  ]
  count = length(var.userid)
  name             = "${var.repo_readonly_username}_${var.userid[count.index]}"
  username         = "${var.repo_readonly_username}_${var.userid[count.index]}"
  password         = "superPassword1${var.userid[count.index]}"
  email            = "ro_${var.userid[count.index]}@user.create"
  is_admin         = false
  projects_limit   = 1
  can_create_group = false
  is_external      = true
  reset_password   = false
}

resource "gitlab_user_sshkey" "sc8_ro_user" {
  depends_on = [
    gitlab_user.sc8_ro_user
  ]
  count = length(var.userid)
  user_id    = gitlab_user.sc8_ro_user[count.index].id
  title      = "sc8_ro_user_key_${var.userid[count.index]}"
  key        = var.keys[count.index]
}

resource "gitlab_personal_access_token" "sc8_ro_user" {
  depends_on = [
    gitlab_user.sc8_ro_user
  ]
  count = length(var.userid)
  user_id    = gitlab_user.sc8_ro_user[count.index].id
  name       = "Personal access token"

  scopes = ["read_repository"]
}

resource "gitlab_user" "developer_user" {
  depends_on = [
    gitlab_project.scenario8_projects
  ]
  count = length(var.userid)
  name             = "developer_${var.userid[count.index]}"
  username         = "developer_${var.userid[count.index]}"
  password         = "superPasswordDev1${var.userid[count.index]}"
  email            = "dev_${var.userid[count.index]}@user.create"
  is_admin         = false
  projects_limit   = 1
  can_create_group = false
  is_external      = true
  reset_password   = false
}

resource "gitlab_personal_access_token" "developer" {
  depends_on = [
    gitlab_user.developer_user
  ]
  count = length(var.userid)
  user_id    = gitlab_user.developer_user[count.index].id
  name       = "Personal access token"

  scopes = ["read_repository","write_repository"]
}

resource "gitlab_project_membership" "readers" {
  count = length(var.userid)
  project_id   = gitlab_project.scenario8_projects[count.index].id
  user_id     = gitlab_user.sc8_ro_user[count.index].id
  access_level = "reporter"
}

resource "gitlab_project_membership" "developers" {
  count = length(var.userid)
  project_id   = gitlab_project.scenario8_projects[count.index].id
  user_id     = gitlab_user.developer_user[count.index].id
  access_level = "maintainer"
}

resource "gitlab_repository_file" "buildspecold" {
  depends_on = [
    gitlab_project.scenario8_projects,
    gitlab_personal_access_token.developer,
    gitlab_user.developer_user,
  ]
  count = length(var.userid)
  project   = gitlab_project.scenario8_projects[count.index].id
  file_path = "buildspec.yml"
  branch    = "main"
  content        =         templatefile("${path.module}/vulnerable-buildspec.yml.tftpl", {
            git_lab_token = gitlab_personal_access_token.developer[count.index].token,
            git_lab_userid = var.userid[count.index],
            git_lab_username = gitlab_user.developer_user[count.index].name,
            git_lab_address = var.public_ip,
        })

  author_email   = "Developer@example.com"
  author_name    = "Developer"
  commit_message = "add buildspec.yml init file"
}

resource "null_resource" "update_files_git" {
  depends_on = [
    gitlab_project.scenario8_projects,
    gitlab_repository_file.buildspecold
  ]
  count = length(var.userid)
  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    
    command     = <<BASH
    set -e
    curl -s -w -XPOST --header "Content-Type: application/json"  --header "PRIVATE-TOKEN: ${var.gitlab_token}" --data "@update.json" http://${var.public_ip}/api/v4/projects/${gitlab_project.scenario8_projects[count.index].id}/repository/commits
BASH
  }

}

resource "gitlab_repository_file" "Dockerfile" {
  depends_on = [
    gitlab_project.scenario8_projects,
    null_resource.update_files_git
  ]
  count = length(var.userid)
  project   = gitlab_project.scenario8_projects[count.index].id
  file_path = "Dockerfile"
  branch    = "main"
  content        = file("${path.module}/../../assets/src/Dockerfile")
  author_email   = "Developer@example.com"
  author_name    = "Developer"
  commit_message = "add Dockerfile file"
}

resource "gitlab_repository_file" "requirements" {
  depends_on = [
    gitlab_project.scenario8_projects,
    gitlab_repository_file.Dockerfile
  ]
  count = length(var.userid)
  project   = gitlab_project.scenario8_projects[count.index].id
  file_path = "requirements.txt"
  branch    = "main"
  content        = file("${path.module}/../../assets/src/requirements.txt")
  author_email   = "Developer@example.com"
  author_name    = "Developer"
  commit_message = "add requirements.txt file"
}

resource "gitlab_repository_file" "app" {
  depends_on = [
    gitlab_project.scenario8_projects,
    gitlab_repository_file.requirements
  ]
  count = length(var.userid)
  project   = gitlab_project.scenario8_projects[count.index].id
  file_path = "app.py"
  branch    = "main"
  content        = file("${path.module}/../../assets/src/app${count.index}.py")
  author_email   = "Developer@example.com"
  author_name    = "Developer"
  commit_message = "add app.py file"
}

resource "null_resource" "disable_gitlab_signin" {
  depends_on = [
    gitlab_project.scenario8_projects,
    gitlab_repository_file.app
  ]
  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    interpreter = ["bash", "-c"]
    
    command     = <<BASH
    set -e
    curl --silent --request PUT --header 'Content-Type: application/json' --header 'PRIVATE-TOKEN: ${var.gitlab_token}' 'http://${var.public_ip}/api/v4/application/settings' --data '{ "signup_enabled":"false", "password_authentication_enabled_for_web":"false", "password_authentication_enabled_for_git":"false"}'
BASH
  }
}
