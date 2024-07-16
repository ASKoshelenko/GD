# Database creation
resource "aws_dynamodb_table" "targetdb" {
  count = length(local.users)
  hash_key         = "id"
  name             = "${var.targetdb_name}-${local.users[count.index].userid}"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  billing_mode = "PAY_PER_REQUEST"
 
  attribute {
    name = "id"
    type = "S"
   }
}

# Creation items for dynamodb table
resource "aws_dynamodb_table_item" "targetdb" {
  count = length(local.users)
# countdb = length(local.targetdb_data)
  table_name = aws_dynamodb_table.targetdb[count.index].name
  hash_key   = aws_dynamodb_table.targetdb[count.index].hash_key
  item = <<ITEM
  {
    "id"         : { "S": "${local.targetdb_data[0].id}" }, 
    "amount"     : { "N": "${local.targetdb_data[0].amount}" },
    "cardnumber" : { "S": "${local.targetdb_data[0].cardnumber}" },
    "firstname"  : { "S": "${local.targetdb_data[0].firstname}" },
    "lastname"   : { "S": "${local.targetdb_data[0].lastname}" }
  }
ITEM
}
