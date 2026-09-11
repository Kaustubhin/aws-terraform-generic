resource "aws_eks_cluster" "this" {
  for_each = var.clusters

  name     = each.key
  role_arn = each.value.cluster_role_arn
  version  = try(each.value.kubernetes_version, "1.29")

  vpc_config {
    subnet_ids              = each.value.subnet_ids
    endpoint_public_access  = try(each.value.endpoint_public_access, true)
    endpoint_private_access = try(each.value.endpoint_private_access, true)
  }

  tags = try(each.value.tags, {})
}

resource "aws_eks_node_group" "this" {
  for_each = var.clusters

  cluster_name    = aws_eks_cluster.this[each.key].name
  node_group_name = try(each.value.node_group_name, "${each.key}-ng")
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids
  instance_types  = try(each.value.node_instance_types, ["t3.medium"])
  capacity_type   = try(each.value.capacity_type, "ON_DEMAND")

  scaling_config {
    desired_size = try(each.value.desired_size, 2)
    min_size     = try(each.value.min_size, 1)
    max_size     = try(each.value.max_size, 3)
  }

  update_config {
    max_unavailable = 1
  }

  tags = try(each.value.tags, {})

  lifecycle {
    create_before_destroy = true
  }
}
