locals {
  application_log_conf = <<-EOT
    [INPUT]
        Name tail
        Tag app.*
        Exclude_Path /var/log/containers/cloudwatch-agent*, /var/log/containers/fluent-bit*, /var/log/containers/aws-node*, /var/log/containers/kube-proxy*
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        DB /var/fluent-bit/state/flb_container.db
        Mem_Buf_Limit 50MB
        Skip_Long_Lines On
        Refresh_Interval 10
        Rotate_Wait 30
        storage.type filesystem
        Read_from_Head Off

    [INPUT]
        Name tail
        Tag app.*
        Path /var/log/containers/fluent-bit*
        multiline.parser docker, cri
        DB /var/fluent-bit/state/flb_log.db
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
        Refresh_Interval 10
        Read_from_Head Off

    [INPUT]
        Name tail
        Tag app.*
        Path /var/log/containers/cloudwatch-agent*
        multiline.parser docker, cri
        DB /var/fluent-bit/state/flb_cwagent.db
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
        Refresh_Interval 10
        Read_from_Head Off

    [FILTER]
        Name kubernetes
        Match app.*
        Kube_URL https://kubernetes.default.svc:443
        Kube_Tag_Prefix app.var.log.containers.
        Merge_Log On
        Merge_Log_Key log_processed
        K8S-Logging.Parser On
        K8S-Logging.Exclude Off
        Labels On
        Annotations On
        Buffer_Size 0

    [OUTPUT]
        Name cloudwatch_logs
        Match app.*
        region ${var.aws_region}
        log_group_name /aws/eks/${var.cluster_name}/aws-fluentbit/fallback
        log_stream_prefix  $${HOSTNAME}-
        log_group_template /aws/eks/${var.cluster_name}/$kubernetes['namespace_name'].$kubernetes['labels']['app.kubernetes.io/name']
        log_stream_template $kubernetes['pod_name'].$kubernetes['container_name']
        auto_create_group true
        log_retention_days 3
        workers 1
  EOT
}
