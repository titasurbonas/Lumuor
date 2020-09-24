
# get accout id 
$account_id=aws sts get-caller-identity | Select-String "Account" | % {$_ -replace '\D+([0-9]*).*','$1'}

$dynamodb_table_name=("{0}-state-lock" -f $account_id)
$s3_state_file=("{0}-state-file" -f $account_id)

aws dynamodb create-table --table-name $dynamodb_table_name --key-schema AttributeName=LockID,KeyType=HASH `
                              --attribute-definitions AttributeName=LockID,AttributeType=S `
                              --provisioned-throughput ReadCapacityUnits=2,WriteCapacityUnits=2

aws s3 mb s3://${s3_state_file}



