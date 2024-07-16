#  # Read list of cidr from file
#  data "local_file" "whitelist_epam_by_ru" {
#    filename = "${path.module}/../../whitelist_epam-by-ru.txt"
#  }
#  data "local_file" "whitelist_epam_europe" {
#    filename = "${path.module}/../../whitelist_epam-europe.txt"
#  }
#  data "local_file" "whitelist_epam_world" {
#    filename = "${path.module}/../../whitelist_epam-world.txt"
#  }

#  locals {
#      read_epam_by_ru = split( "\n", data.local_file.whitelist_epam_by_ru.content)
#      cidrs_by_ru = [
#          for cidr_by_ru in local.read_epam_by_ru:
#             cidr_by_ru
#             if cidr_by_ru != ""
#      ]
#      read_epam_europe = split( "\n", data.local_file.whitelist_epam_europe.content)
#      cidrs_europe = [
#          for cidr_europe in local.read_epam_europe:
#             cidr_europe
#             if cidr_europe != ""
#      ]
#      read_epam_world = split( "\n", data.local_file.whitelist_epam_world.content)
#      cidrs_world = [
#          for cidr_world in local.read_epam_world:
#             cidr_world
#             if cidr_world != ""
#      ]

#  }
