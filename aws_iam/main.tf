provider "aws" {
    region = "us-west-2"    
}


resource "aws_iam_user" "admin_user" {
    name = "Dravid"
    tags = {
        Description = "Tech lead"
    } 
}

resource "aws_iam_policy" "adminUser" {
    name = "AdminUsers"
    # EOF this is a delimiter and can fit in any json in between
    # we could use EOF but a best practice is to separate json in a file like below
    policy = file("admin-policy.json")
}

# arn is amazon unique reference number 
resource "aws_iam_user_policy_attachment" "dravid-admin-access" {
    user = aws_iam_user.admin_user.name
    policy_arn = aws_iam_policy.adminUser.arn
}