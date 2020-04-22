#!/bin/bash

# commands block ALL containers from using the instance profile credentials
# TODO: Make sure infra managements pods are not blocked before enabling it for nodes
#yum install -y iptables-services
#iptables --insert FORWARD 1 --in-interface eni+ --destination 169.254.169.254/32 --jump DROP
#iptables-save | tee /etc/sysconfig/iptables
#systemctl enable --now iptables

# Sysctl changes
## Disable IPv6
cat <<EOF > /etc/sysctl.d/10-disable-ipv6.conf
# disable ipv6 config
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

## Kube network optimisation.
## Stolen from this guy: https://blog.codeship.com/running-1000-containers-in-docker-swarm/
cat <<EOF > /etc/sysctl.d/99-kube-net.conf
# Have a larger connection range available
net.ipv4.ip_local_port_range=1024 65000

# Reuse closed sockets faster
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15

# The maximum number of "backlogged sockets".  Default is 128.
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096

# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# Various network tunables
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216
#vm.min_free_kbytes=65536

# Connection tracking to prevent dropped connections (usually issue on LBs)
net.netfilter.nf_conntrack_max=262144
net.ipv4.netfilter.ip_conntrack_generic_timeout=120
net.netfilter.nf_conntrack_tcp_timeout_established=86400

# ARP cache settings for a highly loaded docker swarm
net.ipv4.neigh.default.gc_thresh1=8096
net.ipv4.neigh.default.gc_thresh2=12288
net.ipv4.neigh.default.gc_thresh3=16384
EOF

# Disable THP
cat <<EOF > /etc/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF

systemctl restart systemd-sysctl.service

%{ if cross_account_ecr_enabled }
su - ec2-user -c "$(aws ecr get-login --no-include-email --region us-east-1 --registry-ids ${registry_ids})"
FILE='/etc/crontab'
echo "0 */6 * * * ec2-user \$(aws ecr get-login --no-include-email --region us-east-1 --registry-ids ${registry_ids})" >> "$FILE"
%{ endif }

/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' \
    --b64-cluster-ca '${certificate_authority_data}' '${cluster_name}' \
    --kubelet-extra-args \
        "--kube-reserved cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi \
        --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi \
        --eviction-hard memory.available<500Mi,nodefs.available<10% \
        --allowed-unsafe-sysctls net.core.somaxconn \
        ${bootstrap_extra_args}"
