resource "lxd_storage_pool" "dir_storage_pool" {
  name   = "dir-storage-pool"
  driver = "dir"
  config = {
    #    source = "/var/lib/lxd/storage-pools/dir-storage-pool"
    source = "/var/snap/lxd/common/lxd/storage-pools/dir-storage-pool"
  }
}

resource "lxd_profile" "dirfs_profile" {
  name        = "fs-dir"
  description = "LXD dirfs profile"

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.dir_storage_pool.name
      path = "/"
    }
  }
}

resource "lxd_profile" "limits_profile" {
  name        = "limits"
  description = "LXD limits profile"

  config = {
    "limits.cpu"         = 12
    "limits.memory"      = "24GB"
    "limits.memory.swap" = "false"
  }
}

resource "lxd_network" "adm_network" {
  name = "adm-network"
  config = {
    "ipv4.address" = "10.0.10.1/24"
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
  }
}

resource "lxd_profile" "adm_profile" {
  name        = "nw-adm"
  description = "LXD profile for administrative containers"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.adm_network.name
    }
  }
}

resource "lxd_profile" "privileged_profile" {
  name        = "privileged"
  description = "LXD privileged container which may create nested cgroups"

  config = {
    #  for a privileged container which may create nested cgroups
    "security.privileged" = "true"
    "security.nesting"    = "true"

    # depending on the kernel of your host system, you need to add
    # further kernel modules here. The ones listed above are for
    # networking and for docker's overlay filesystem.
    "linux.kernel_modules" = "overlay,br_netfilter,ip_tables,ip6_tables,ip_vs,ip_vs_rr,ip_vs_wrr,ip_vs_sh,netlink_diag,nf_nat,overlay,xt_conntrack"
    # linux.kernel_modules = "overlay,nf_nat,ip_tables,ip6_tables,netlink_diag,br_netfilter,xt_conntrack,nf_conntrack,ip_vs,vxlan"

    "raw.lxc" = <<-EOF
      lxc.apparmor.profile=unconfined
      lxc.cap.drop=
      lxc.cgroup.devices.allow=a
      lxc.mount.auto=proc:rw sys:rw
    EOF
  }

  device {
    name = "kmsg"
    type = "unix-char"

    properties = {
      source = "/dev/kmsg"
      path   = "/dev/kmsg"
    }
  }
}
