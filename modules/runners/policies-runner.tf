data "aws_caller_identity" "current" {}

resource "aws_iam_role" "runner" {
  name                 = "${var.prefix}-runner-role"
  assume_role_policy   = templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  path                 = local.role_path
  permissions_boundary = var.role_permissions_boundary
  tags                 = local.tags
}

resource "aws_iam_instance_profile" "runner" {
  name = "${var.prefix}-runner-profile"
  role = aws_iam_role.runner.name
  path = local.instance_profile_path
}

resource "aws_iam_role_policy" "runner_session_manager_aws_managed" {
  name   = "runner-ssm-session"
  count  = var.enable_ssm_on_runners ? 1 : 0
  role   = aws_iam_role.runner.name
  policy = templatefile("${path.module}/policies/instance-ssm-policy.json", {})
}

resource "aws_iam_role_policy" "ssm_parameters" {
  name = "runner-ssm-parameters"
  role = aws_iam_role.runner.name
  policy = templatefile("${path.module}/policies/instance-ssm-parameters-policy.json",
    {
      arn_ssm_parameters_prefix = "arn:${var.aws_partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}-*"
      arn_ssm_parameters_path   = "arn:${var.aws_partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/*"
    }
  )
}

resource "aws_iam_role_policy" "dist_bucket" {
  count = var.enable_runner_binaries_syncer ? 1 : 0

  name = "distribution-bucket"
  role = aws_iam_role.runner.name
  policy = templatefile("${path.module}/policies/instance-s3-policy.json",
    {
      s3_arn = "${var.s3_runner_binaries.arn}/${var.s3_runner_binaries.key}"
    }
  )
}

resource "aws_iam_role_policy" "describe_tags" {
  name   = "runner-describe-tags"
  role   = aws_iam_role.runner.name
  policy = file("${path.module}/policies/instance-describe-tags-policy.json")
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  count      = length(var.runner_iam_role_managed_policy_arns)
  role       = aws_iam_role.runner.name
  policy_arn = element(var.runner_iam_role_managed_policy_arns, count.index)
}


resource "aws_iam_role_policy" "ec2" {
  name   = "ec2"
  role   = aws_iam_role.runner.name
  policy = templatefile("${path.module}/policies/instance-ec2.json", {})
}

data "aws_iam_policy_document" "helix_agent_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:GetObjectRetention",
      "s3:GetObjectVersionTagging",
      "s3:ListBucketVersions",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAttributes",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::enverus-security-shared-files/*",
      "arn:aws:s3:::enverus-security-shared-files"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "helix_agent_policy" {
  name_prefix = "Helix-Agent-policy"
  description = "IAM Policy to allow installation of Helix-Agent securiy"
  policy      = data.aws_iam_policy_document.helix_agent_policy.json
}

resource "aws_iam_role_policy_attachment" "helix_agent_attachment" {
  role       = aws_iam_role.runner.name
  policy_arn = aws_iam_policy.helix_agent_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// see also logging.tf for logging and metrics policies
