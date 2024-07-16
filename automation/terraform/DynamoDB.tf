
# Database creation
 resource "aws_dynamodb_table" "users" {
   hash_key         = "email"
   name             = var.dbName
   stream_enabled   = true
   stream_view_type = "NEW_AND_OLD_IMAGES"
   read_capacity    = 1
   write_capacity   = 1
 
   attribute {
     name = "email"
     type = "S"
   }
 
   tags = {
     Name        = "dynamodb-table-users"
   }
 }

# Creation items for dynamodb table
  resource "aws_dynamodb_table_item" "users" {
  count = length(local.emails)
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  item = <<ITEM
  {
    "email": { "S": "${local.emails[count.index]}" },
    "scenarios": {
        "M": 
        { 
            "scenario1": 
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "N"   : "1580900058" },
                    "destroy_date": { "N"   : "1580908058" },
                    "user_events" : { "L": [] }
                }
            },
            "scenario2": 
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "N"   : "1580900058" },
                    "destroy_date": { "N"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            },
            "scenario3": 
            {
                "M": 
                {
                    "passed"         : { "BOOL": false },
                    "cheat"          : { "BOOL": false },
                    "deploy_date"    : { "N"   : "1580900058" },
                    "destroy_date"   : { "N"   : "1580908058" },
                    "instance_events": { "L"   : [] },
                    "user_events"    : { "L"   : [] }
                }
            },
            "scenario4":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "N"   : "1580900058" },
                    "destroy_date": { "N"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            },
            "scenario5":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "N"   : "1580900058" },
                    "destroy_date": { "N"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            },
            "scenario6":
            {
                "M": 
                {
                    "passed"      : { "BOOL": false },
                    "cheat"       : { "BOOL": false },
                    "deploy_date" : { "N"   : "1580900058" },
                    "destroy_date": { "N"   : "1580908058" },
                    "events"      : { "L"   : [] }
                }
            }
        }
    },
    "notifications": {
    "M": {    

    }
  }
ITEM
}

