{ device ? "/dev/sda", ... }:
{
  disko.devices.disk.main = {
    inherit device;
    type = "disk";
    content.type = "gpt";
    content.partitions.ESP = {
      type = "EF00";
      size = "500M";
      content.type = "filesystem";
      content.format = "vfat";
      content.mountpoint = "/boot";
      content.mountOptions = [ "umask=0077" ];
    };
    content.partitions.root = {
      size = "100%";
      content.type = "filesystem";
      content.format = "ext4";
      content.mountpoint = "/";
    };
  };
}