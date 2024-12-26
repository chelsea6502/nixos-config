{ pkgs, ... }: {
  boot.kernel.sysctl = {

    "dev.tty.ldisc_autoload" = "0";
    # Network
    "net.ipv4.tcp_timestamps" = "0";
    "net.core.netdev_max_backlog" = "250000";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.ip_forward" = "1";
    "net.ipv4.tcp_syncookies" = "1";
    "net.ipv4.tcp_synack_retries" = "5";
    "net.ipv4.conf.default.send_redirects" = "0";
    "net.ipv4.conf.all.send_redirects" = "0";
    "net.ipv4.conf.default.accept_source_route" = "0";
    "net.ipv4.conf.all.accept_source_route" = "0";
    "net.ipv4.conf.default.rp_filter" = "1";
    "net.ipv4.conf.all.forwarding" = "0";
    "net.ipv4.conf.all.rp_filter" = "1";
    "net.ipv4.conf.default.log_martians" = "1";
    "net.ipv4.conf.all.log_martians" = "1";
    "net.ipv4.conf.default.accept_redirects" = "0";
    "net.ipv4.conf.all.accept_redirects" = "0";
    "net.ipv4.conf.default.shared_media" = "0";
    "net.ipv4.conf.all.shared_media" = "0";
    "net.ipv4.conf.default.arp_announce" = "2";
    "net.ipv4.conf.all.arp_announce" = "2";
    "net.ipv4.conf.default.arp_ignore" = "1";
    "net.ipv4.conf.all.arp_ignore" = "1";
    "net.ipv4.conf.default.drop_gratuitous_arp" = "1";
    "net.ipv4.conf.all.drop_gratuitous_arp" = "1";
    "net.ipv4.icmp_echo_ignore_broadcasts" = "1";
    "net.ipv4.icmp_ignore_bogus_error_responses" = "1";
    "net.ipv4.tcp_rfc1337" = "1";
    "net.ipv4.ip_local_port_range" = "1024 65535";
    "net.ipv4.tcp_sack" = "0";
    "net.ipv4.tcp_dsack" = "0";
    "net.ipv4.tcp_fack" = "0";
    "net.ipv4.tcp_adv_win_scale" = "1";
    "net.ipv4.tcp_mtu_probing" = "1";
    "net.ipv4.tcp_base_mss" = "1024";
    "net.ipv4.tcp_rmem" = "4096 87380 8388608";
    "net.ipv4.tcp_wmem" = "4096 87380 8388608";

    # Kernel
    "kernel.randomize_va_space" = "2";
    "kernel.sysrq" = "0";
    "kernel.core_uses_pid" = "1";
    "kernel.kptr_restrict" = "2";
    "kernel.yama.ptrace_scope" = "3";
    "kernel.dmesg_restrict" = "1";
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_bpf_disabled" = "1";
    "kernel.kexec_load_disabled" = "1";
    "kernel.unprivileged_userns_clone" = "1";
    "kernel.pid_max" = "32768";
    "kernel.panic" = "20";
    "kernel.perf_event_paranoid" = "3";
    "kernel.perf_cpu_time_max_percent" = "1";
    "kernel.perf_event_max_sample_rate" = "1";

    # File System
    "fs.suid_dumpable" = "0";
    "fs.protected_hardlinks" = "1";
    "fs.protected_symlinks" = "1";
    "fs.protected_fifos" = "2";
    "fs.protected_regular" = "2";
    "fs.file-max" = "9223372036854775807";
    "fs.inotify.max_user_watches" = "524288";

    # Virtualization
    "vm.mmap_min_addr" = "65536";
    "vm.mmap_rnd_bits" = "32";
    "vm.mmap_rnd_compat_bits" = "16";
    "vm.unprivileged_userfaultfd" = "0";

  };

  # Misc. security!
  nix.settings.allowed-users = [ "@wheel" ];
  security.sudo.execWheelOnly = true;
  systemd.coredump.enable = false;
  security.chromiumSuidSandbox.enable = true; # enable the chromium sandbox
  #services.clamav.daemon.enable = true; #enable clamav and update it - requires clamav to be installed
  #services.clamav.updater.enable = true;
  services.syslogd.enable = true;
  services.syslogd.extraConfig = ''
    *.*  -/var/log/syslog
  '';
  services.journald.forwardToSyslog = true;
}
