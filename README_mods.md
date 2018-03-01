# Forked MotionEyeOS Modifications and Configuration

This is a modified version of [ccrisan's MotionEyeOS](https://github.com/ccrisan/motioneyeos).
This is completely untested and highly experimental. __*Use at your own risk.*__

Modifications applied so far:

- Split media and system files into separate partitions to workaround [system lockup when storage partition is full](https://github.com/ccrisan/motioneyeos/issues/1164).
- Firmware upgrade defaults to this [forked releases](https://github.com/jasaw/motioneyeos/releases).
- Logging:
  - Log to RAM
  - Reduced maximum log file size
  - Rotate log files more often
- Added `gpu_stat` script to poll available GPU memory (useful for GPU memory optimisation).
- Added `ldr-reader` to read CdS photocell.
- Added `overlay_temper` script to overlay CPU temperature on video stream.
- Hacked `ffmpeg` to use hardware acceleration when decoding H264 video input.

Note that this fork is __*not*__ compatible with ccrisan's MotionEyeOS because of separate partitions for media and system files. The only way to migrate back to ccrisan's MotionEyeOS is to reflash your SD card.



## Typical Configurations


### Pi Zero W

* Resolution: 1280 x 720 or 1024 x 768
* fps: 10
* Movie format: H.264
* Movie quality: 25%
* Frame Change Threshold: 5.5%
* Auto Noise Detection: On
* Light Switch Detection: 75%
* Despeckle Filter: On
* Motion Gap: 60 seconds
* Captured Before: 30 frames
* Captured After: 100 frames
* Minimum Motion Frames: 10 frames
* Add `tvservice -o` to /data/etc/userinit.sh to disable HDMI (saves 30mA, lower CPU temperature).
* Run `EDITOR=vi crontab -e`, and add `* * * * * /usr/bin/overlay_temper` to overlay CPU temperature every minute.
* Underclock the hardware to reduce CPU temperature. Edit `/boot/config.txt`
  ```
  gpu_mem=70
  gpu_mem_256=70
  gpu_mem_512=70
  dtparam=i2c_arm=on
  dtparam=i2s=on
  dtparam=spi=on
  dtparam=audio=on
  disable_camera_led=1
  arm_freq=700
  gpu_freq=300
  sdram_freq=450
  over_voltage=0
  ```


### How to automatically backup media files to Dropbox via a file server

Set up camera upload folder permissions.
1. Create a new user named `seccam` for the purpose of backing up files.
2. Create a new group called `secmedia` and add `seccam` and the Dropbox owner into the group.
3. Allow secmedia group to access the Dropbox media folder.
   ```
   chgrp secmedia Dropbox
   chmod 710 Dropbox
   chgrp -R secmedia Dropbox/CameraUploads
   ```
4. Enable secmedia group read-write permission for Dropbox/CameraUploads if not already enabled. `chmod 770 Dropbox/CameraUploads`.
5. Create a symlink in `seccam` home directory that points to Dropbox/CameraUploads. `ln -s /home/$DROPBOX_OWNER/Dropbox/CameraUploads CameraUploads`.

Set up SSH key login from MotionEyeOS to the file server.
1. On MotionEyeOS, copy `/data/etc/ssh_host_rsa_key.pub` to file server.
2. On the file server, add the copied `ssh_host_rsa_key.pub` to authorized_keys by running `cat ssh_host_rsa_key.pub >> authorized_keys`.
3. On MotionEyeOS, login to remote server by running `ssh -i /data/etc/ssh_host_rsa_key -o UserKnownHostsFile=/data/etc/known_hosts seccam@SERVER_HOSTNAME`

Set up rsync to backup media files.
1. Try running rsync with verbose output to make sure rsync works. On MotionEyeOS, run ```if [ -z `pidof rsync` ]; then timeout -t 1800 nice -n 19 rsync -av --progress --delete --bwlimit=800 --exclude='.keep' -e "nice -n 19 ssh -i /data/etc/ssh_host_rsa_key -o UserKnownHostsFile=/data/etc/known_hosts" /home/ftp/sdcard/ seccam@SERVER_HOSTNAME:CameraUploads/ ; fi```.
2. Add additional security on the file server by limiting SSH login to running rsync command.
   Create validate-rsync.sh file.
   ```
   touch ~/validate-rsync.sh
   chmod +x ~/validate-rsync.sh
   ```
   Put the code below into validate-rsync.sh file.
   ```
   #!/bin/sh
   case "$SSH_ORIGINAL_COMMAND" in
   *\&*)
   echo "Rejected"
   ;;
   *\;*)
   echo "Rejected"
   ;;
   rsync\ --server*)
   $SSH_ORIGINAL_COMMAND
   ;;
   *)
   echo "Rejected"
   ;;
   esac
   ```
   Add to the ~/.ssh/authorized_keys file: `command="/home/seccam/validate-rsync.sh" ssh-rsa AAAAB3NzaC1yc2... root@meye-01`.
3. Try the rsync command again. If rsync works, rsync `--progress` and `-v` arguments can be replaced by `-q`.
   Example: ```if [ -z `pidof rsync` ]; then timeout -t 1800 nice -n 19 rsync -aq --delete --bwlimit=800 --exclude='.keep' -e "nice -n 19 ssh -i /data/etc/ssh_host_rsa_key -o UserKnownHostsFile=/data/etc/known_hosts" /home/ftp/sdcard/ seccam@SERVER_HOSTNAME:CameraUploads/ ; fi```
4. Add the rsync command to crontab. Run `EDITOR=vi crontab -e` and add:
   ```0 * * * * if [ -z `pidof rsync` ]; then timeout -t 1800 nice -n 19 rsync -aq --delete --bwlimit=800 --exclude='.keep' -e "nice -n 19 ssh -i /data/etc/ssh_host_rsa_key -o UserKnownHostsFile=/data/etc/known_hosts" /home/ftp/sdcard/ seccam@SERVER_HOSTNAME:CameraUploads/ ; fi```
5. Add the same rsync command to Motion Notification --> Run an End Command.
