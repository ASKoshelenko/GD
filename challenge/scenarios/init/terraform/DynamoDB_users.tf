# Creation items for dynamodb table
  resource "aws_dynamodb_table_item" "users" {
  count = length(local.users)
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  item = <<ITEM
  {
    "userid"       : { "S": "${local.users[count.index].userid}" }, 
    "username"     : { "S": "${local.users[count.index].username}" },
    "email"        : { "S": "${local.users[count.index].email}" },
    "category"     : { "S": "${local.users[count.index].category}" },
    "notifications": { "M": {"test" :{ "S":"sometext"} } },
    "scenarios": 
    {
        "M": 
        { 
            "${var.scenarios[0]}": 
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "${timestamp()}" },
                    "destroy_date": { "S"   : "${timeadd(timestamp(), "4h")}"},
                    "events" : { "L": [] }
                }
            },
            "${var.scenarios[1]}": 
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            },
            "${var.scenarios[2]}": 
            {
                "M": 
                {
                    "passed"         : { "BOOL": false },
                    "cheat"          : { "BOOL": false },
                    "deploy_date"    : { "S"   : "1580900058" },
                    "destroy_date"   : { "S"   : "1580908058" },
                    "instance_events": { "L"   : [] },
                    "user_events"    : { "L"   : [] }
                }
            },
            "${var.scenarios[3]}":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            },
            "${var.scenarios[4]}":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" }
                }
            },
            "${var.scenarios[5]}":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" }
                }
            },
            "${var.scenarios[6]}":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" }
                }
            },
            "${var.scenarios[7]}":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "S"   : "1580900058" },
                    "destroy_date": { "S"   : "1580908058" }
                }
            }
        }
    }
  }
ITEM
}

# Database creation
 resource "aws_dynamodb_table" "users" {
   hash_key         = "userid"
   name             = var.dbName
   stream_enabled   = true
   stream_view_type = "NEW_AND_OLD_IMAGES"
   billing_mode = "PAY_PER_REQUEST"
 
   attribute {
     name = "userid"
     type = "S"
   }
 }