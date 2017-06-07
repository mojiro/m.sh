# m.sh
A [m]anagement script for your webserver.
It manages backups (not yet restores :) plus some extra operations for Drupal websites.

I created it to test my abilities on Bash. It is easy-readable and my aim is it to keep it close to 1000 lines.

Current version: 1.7.3
Latest update: 2017-05-06

```
Usage:
  ./m.sh [options] [site1] [site2] [site3]

  --config=file     Define Configuration file. Default .m.conf

  -q, --quiet       Quiet, without output.
  -s, --status      Prints summarized Site status.
  -v, --version     Prints m.sh version.
  -h, --help        Shows this text.

  -a, --all         Execute on all sites.
  -w, --www         Execute only WWW. It does not apply to rsync/FTP syncs.
  -d, --db          Execute only DB. It does not apply to rsync/FTP syncs.

  -b, --backup      Backup operation. Default if nothing else is specified.
  -c, --clean       Delete Backup files that have same Hash. Keeps the oldest.
  -l, --list        Lists Backup files.
  -i, --info        Shows Site info.

  -f, --ftp         Sync files to Remote rsync Server.
  -r, --rsync       Sync files to Remote FTP Server.

  Only for Drupal:
  -u, --update      Update site code.
  -t, --truncate    Truncate Cache tables in MySQL.
  -0, --offline     Set Site Offline.
  -1, --online      Set Site Online.

Example:
  ./m.sh -bcwr site1.org site2.edu
    1) It will Backup only WWW.
    2) Then it will Clean-up at WWW.
    3) At the end it will sync Backup folder to Remote rsync Server.
```

```
root@monster:~/.scripts# ./m.sh 

Type  Site                Backup         DB                 Backup
 D7   site1.gr            20170430-0949  site1_gr           20170430-0949
 J    example.gr          20170430-0949  example_org        20170430-0949
 D7   demo1.example.org   20170430-0949  demo1_example_org  20170329-1330
 O    drupal-7.54         20170529-1820
 D7   drupal.example.org  20170430-0949  drupal_example_org 20170430-0949
 O    demo1.ie            20170430-0949
 D7   demo2.example.org   20170430-0949  demo2_example_org  20170329-1329
 O    site2.gr            20170430-0949
 J    site3.com           20170430-0949  site3_com_db       20170430-0949
 W4   test.com            20170430-0949  test_com           20170430-0949

root@monster:~/.scripts# ./m.sh site1.gr -i

Site:
  site1.gr

  Type:     Drupal 7
  Version:  7.54
  Database: site1_gr
  Username: site1_gr
  Password: 2fssg454

```