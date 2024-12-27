{ pkgs, ... }: {
  boot = {
    #loader.systemd-boot.enable = true;
    #loader.efi.canTouchEfiVariables = true;
    #supportedFilesystems = [ "ntfs" ];
    #kernelPackages = pkgs.linuxPackages_6_6_hardened;
    #   extraModulePackages = with config.boot.kernelPackages; [ lkrg_hardened ]; # broken package
    # hardening systemd-boot ∨
    kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "pti=on"
      "vsyscall=none"
      "debugfs=off"
      "oops=panic"
      "module.sig_enforce=1"
      "lockdown=off"
      "mce=0"
      "quiet"
      "loglevel=2"
      #"ipv6.disable=1"
      "spectre_v2=on"
      "spec_store_bypass_disable=on" # these two mitigate spectre, minimal resource usage
      "kvm.nx_huge_pages=force" # this one can increase memory usage, especially with hypervisors that use kvm
    ];
  };
  # hardening proc
  fileSystems."/proc" = {
    fsType = "proc";
    device = "proc";
    options = [ "nosuid" "nodev" "noexec" "hidepid=2" ];
    neededForBoot = true;
  };
  # make sudo required for accessing process lists
  users.groups.proc = { };
  systemd.services.systemd-logind.serviceConfig = {
    SupplementaryGroups = [ "proc" ];
  };
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
    #"n-hdlc"
    #"ax25"
    #"netrom"
    #"x25"
    #"rose"
    #"decnet"
    #"econet"
    #"af_802154"
    #"ipx"
    #"appletalk"
    #"psnap"
    #"p8023"
    #"p8022"
    #"can"
    #"atm"
    #"cramfs"
    #"freevxfs"
    #"jffs2"
    #"hfs"
    #"hfsplus"
    #"udf"
    #"vivid"
    #"thunderbolt"
    #"firewire-core"
  ];

  boot.kernel.sysctl = {
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

    # IPv6
    "net.ipv6.conf.default.forwarding" = "0";
    "net.ipv6.conf.all.forwarding" = "0";
    "net.ipv6.conf.default.router_solicitations" = "0";
    "net.ipv6.conf.all.router_solicitations" = "0";
    "net.ipv6.conf.default.accept_ra_rtr_pref" = "0";
    "net.ipv6.conf.all.accept_ra_rtr_pref" = "0";
    "net.ipv6.conf.default.accept_ra_pinfo" = "0";
    "net.ipv6.conf.all.accept_ra_pinfo" = "0";
    "net.ipv6.conf.default.accept_ra_defrtr" = "0";
    "net.ipv6.conf.all.accept_ra_defrtr" = "0";
    "net.ipv6.conf.default.autoconf" = "0";
    "net.ipv6.conf.all.autoconf" = "0";
    "net.ipv6.conf.default.dad_transmits" = "0";
    "net.ipv6.conf.all.dad_transmits" = "0";
    "net.ipv6.conf.default.max_addresses" = "1";
    "net.ipv6.conf.all.max_addresses" = "1";
    "net.ipv6.conf.all.use_tempaddr" = "2";
    "net.ipv6.conf.default.accept_redirects" = "0";
    "net.ipv6.conf.all.accept_redirects" = "0";
    "net.ipv6.conf.default.accept_source_route" = "0";
    "net.ipv6.conf.all.accept_source_route" = "0";
    "net.ipv6.icmp.echo_ignore_all" = "1";
    "net.ipv6.icmp.echo_ignore_anycast" = "1";
    "net.ipv6.icmp.echo_ignore_multicast" = "1";
    "net.ipv6.conf.all.disable_ipv6" = "1";
    "net.ipv6.conf.default.disable_ipv6" = "1";
    "net.ipv6.conf.lo.disable_ipv6" = "1";

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

  systemd.services.systemd-rfkill = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.syslog = {
    serviceConfig = {
      PrivateNetwork = true;
      CapabilityBoundingSet =
        [ "CAP_DAC_READ_SEARCH" "CAP_SYSLOG" "CAP_NET_BIND_SERVICE" ];
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      PrivateMounts = true;
      SystemCallArchitectures = "native";
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      ProtectKernelTunables = true;
      RestrictRealtime = true;
      PrivateUsers = true;
      PrivateTmp = true;
      UMask = "0077";
      RestrictNamespace = true;
      ProtectProc = "invisible";
      ProtectHome = true;
      DeviceAllow = false;
      ProtectSystem = "full";
    };
  };

  systemd.services.systemd-journald = {
    serviceConfig = {
      UMask = 77;
      PrivateNetwork = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
    };
  };
  systemd.services.auto-cpufreq = {
    serviceConfig = {
      CapabilityBoundingSet = "";
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateNetwork = true;
      IPAddressDeny = "any";
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectHostname = false;
      MemoryDenyWriteExecute = true;
      ProtectClock = true;
      RestrictNamespaces = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectProc = true;
      ReadOnlyPaths = [ "/" ];
      InaccessiblePaths = [ "/home" "/root" "/proc" ];
      SystemCallFilter = [ "@system-service" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
  systemd.services.NetworkManager-dispatcher = {
    serviceConfig = {
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateUsers = true;
      PrivateDevices = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.display-manager = {
    serviceConfig = {
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true; # so we won't need all of this
    };
  };
  systemd.services.emergency = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # Might need adjustment for emergency access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."getty@tty1" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."getty@tty7" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.NetworkManager = {
    serviceConfig = {
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      SystemCallArchitectures = "native";
      MemoryDenyWriteExecute = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      ProtectKernelTunables = true;
      ProtectHome = true;
      PrivateTmp = true;
      UMask = "0077";
    };
  };
  # systemd.services."nixos-rebuild-switch-to-configuration" = {
  #   serviceConfig = {
  #     ProtectHome = true;
  #     NoNewPrivileges = true; # Prevent gaining new privileges
  #   };
  # };
  # systemd.services."dbus" = {
  #   serviceConfig = {
  #     PrivateTmp = true;
  #     PrivateNetwork = true;
  #     ProtectSystem = "full";
  #     ProtectHome = true;
  #     SystemCallFilter =
  #       "~@clock @cpu-emulation @module @mount @obsolete @raw-io @reboot @swap";
  #     ProtectKernelTunables = true;
  #     NoNewPrivileges = true;
  #     CapabilityBoundingSet = [
  #       "~CAP_SYS_TIME"
  #       "~CAP_SYS_PACCT"
  #       "~CAP_KILL"
  #       "~CAP_WAKE_ALARM"
  #       "~CAP_SYS_BOOT"
  #       "~CAP_SYS_CHROOT"
  #       "~CAP_LEASE"
  #       "~CAP_MKNOD"
  #       "~CAP_NET_ADMIN"
  #       "~CAP_SYS_ADMIN"
  #       "~CAP_SYSLOG"
  #       "~CAP_NET_BIND_SERVICE"
  #       "~CAP_NET_BROADCAST"
  #       "~CAP_AUDIT_WRITE"
  #       "~CAP_AUDIT_CONTROL"
  #       "~CAP_SYS_RAWIO"
  #       "~CAP_SYS_NICE"
  #       "~CAP_SYS_RESOURCE"
  #       "~CAP_SYS_TTY_CONFIG"
  #       "~CAP_SYS_MODULE"
  #       "~CAP_IPC_LOCK"
  #       "~CAP_LINUX_IMMUTABLE"
  #       "~CAP_BLOCK_SUSPEND"
  #       "~CAP_MAC_*"
  #       "~CAP_DAC_*"
  #       "~CAP_FOWNER"
  #       "~CAP_IPC_OWNER"
  #       "~CAP_SYS_PTRACE"
  #       "~CAP_SETUID"
  #       "~CAP_SETGID"
  #       "~CAP_SETPCAP"
  #       "~CAP_FSETID"
  #       "~CAP_SETFCAP"
  #       "~CAP_CHOWN"
  #     ];
  #     ProtectKernelModules = true;
  #     ProtectKernelLogs = true;
  #     ProtectClock = true;
  #     ProtectControlGroups = true;
  #     RestrictNamespaces = true;
  #     MemoryDenyWriteExecute = true;
  #     RestrictAddressFamilies = [ "~AF_PACKET" "~AF_NETLINK" ];
  #     ProtectHostname = true;
  #     LockPersonality = true;
  #     RestrictRealtime = true;
  #     PrivateUsers = true;
  #   };
  # };
  systemd.services.nix-daemon = {
    serviceConfig = {
      ProtectHome = true;
      PrivateUsers = false;
    };
  };
  systemd.services.reload-systemd-vconsole-setup = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      PrivateUsers = true;
      PrivateDevices = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.rescue = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # Might need adjustment for rescue operations
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies =
        "AF_INET AF_INET6"; # Networking might be necessary in rescue mode
      RestrictNamespaces = true;
      SystemCallFilter = [
        "write"
        "read"
        "openat"
        "close"
        "brk"
        "fstat"
        "lseek"
        "mmap"
        "mprotect"
        "munmap"
        "rt_sigaction"
        "rt_sigprocmask"
        "ioctl"
        "nanosleep"
        "select"
        "access"
        "execve"
        "getuid"
        "arch_prctl"
        "set_tid_address"
        "set_robust_list"
        "prlimit64"
        "pread64"
        "getrandom"
      ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny =
        "any"; # May need to be relaxed for network troubleshooting in rescue mode
    };
  };
  systemd.services."systemd-ask-password-console" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # May need adjustment for console access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # A more permissive filter
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."systemd-ask-password-wall" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # A more permissive filter
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.thermald = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true; # Necessary for adjusting cooling policies
      ProtectKernelModules = true; # May need adjustment for module control
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # May require access to specific hardware devices
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = "";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
      DeviceAllow = [ ];
      RestrictAddressFamilies = [ ];
    };
  };
  # systemd.services."user@1000" = {
  #   serviceConfig = {
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #     ProtectKernelTunables = true;
  #     ProtectKernelModules = true;
  #     ProtectControlGroups = true;
  #     ProtectKernelLogs = true;
  #     ProtectClock = true;
  #     ProtectProc = "invisible";
  #     ProcSubset = "pid";
  #     PrivateTmp = true;
  #     PrivateUsers = false; # Be cautious, as this may restrict user operations
  #     PrivateDevices = true;
  #     PrivateIPC = true;
  #     MemoryDenyWriteExecute = true;
  #     NoNewPrivileges = true;
  #     LockPersonality = true;
  #     RestrictRealtime = true;
  #     RestrictSUIDSGID = true;
  #     RestrictAddressFamilies = "AF_INET AF_INET6";
  #     RestrictNamespaces = true;
  #     SystemCallFilter = [ "@system-service" ]; # Adjust based on user needs
  #     SystemCallArchitectures = "native";
  #     UMask = "0077";
  #     IPAddressDeny = "any";
  #   };
  # };
}
