#!/bin/bash

# m.sh               ~ v1.7.4
# Michael Topaloudis ~ Dublin, 2017-06-11
# License            ~ GPL 2.0

# A bash script that simplifies site operations thru console.

#########################################################################################

# Default General Settings
IGNORE='site1.org,site2.net,site3.info'
INCOMPLETEDELETE='1'
KEEPFILES='1'

# Default Directory Settings
DWWW='/var/www'    # WWW Directory
DBU='/home/backup' # BAckup Directory
UWWW='www-data'    # WWW (apache/nginx) User

# Default MySQL Settings
MEN='1'
MUSER='root'
MPASS='1234'
MHOST='localhost'

# Default rsync Settings
RUSER='user'
RKEY="${HOME}/.ssh/id_rsa"
RHOST='example.com'
RPORT='22'
RPATH='~'

# Default FTP Settings
FUSER='user'
FPASS='1234'
FHOST='example.com'
FPORT='21'
FPATH='~'

#########################################################################################

# Script info
APP='m.sh'
VERSION='1.7.4'
CREATOR='Michael Topaloudis'
COPYRIGHT='Dublin, 2017'

DAY=''             # Today (auto)
SOURCE=''          # Script Directory (auto)
SETTINGS='.m.conf' # Settings file
MLOGINPATH=''      # MySQL Client Settings file
MOPTS=''           # MySQL options

# Arguments / Options / Operations
OO=''
OPTSO='O0 OT OB OC OL OF OR OU OI O1'      # Options Order
OPTS=''
#     Var|Arg1|Arg2|ArgX|s_function
OPTS+='OQ|q|quiet|'$'\n'                   # Quiet
OPTS+='OS|s|status|s_status'$'\n'          # Status
OPTS+='OV|v|ver|version|s_version'$'\n'    # Version
OPTS+='OH|h|help|s_help'$'\n'              # Help
OPTS+='OA|a|al|all|alll|'$'\n'             # All
OPTS+='OW|w|ww|www|wwww|'$'\n'             # WWW only
OPTS+='OD|d|db|database|'$'\n'             # DB only
OPTS+='OB|b|bu|bup|backup|s_backup'$'\n'   # Backup
OPTS+='OC|c|clean|clear|s_clean'$'\n'      # Clean
OPTS+='OL|l|list|s_list'$'\n'              # List
OPTS+='OI|i|inf|info|s_info'$'\n'          # Info
OPTS+='OF|f|ftp|s_ftp'$'\n'                # FTP
OPTS+='OR|r|rsync|s_rsync'$'\n'            # rsync
OPTS+='OU|u|upd|update|s_update'$'\n'      # Update
OPTS+='OT|t|truncate|s_truncatecache'$'\n' # Truncate Cache
OPTS+='O0|0|of|off|offline|s_offline'$'\n' # Site Offline
OPTS+='O1|1|on|online|s_online'$'\n'       # Site Online
OPTS+='OM|m|config|configuration|'$'\n'    # Configuration file

# Configuration files
CD7='sites/default/settings.php' # Drupal 7x
CW4='wp-config.php'              # Wordpress 4x
CJ='configuration.php'           # Joomla 2x 3x

# Version files
VD7='includes/bootstrap.inc'                  # Drupal 7x
VW4='wp-includes/version.php'                 # Wordpress 4x
VJ='administrator/manifests/files/joomla.xml' # Joomla 2x 3x

# Site lists
SA=''  # All sites
ST='0' # Temporary list of sites / Counter
SM=''  # Sites to manage

# Info variables
STYPE=''    # Site Type
SVERSION='' # Site Verion
DBNAME=''   # Site Database Name
DBUSER=''   # Site Database Username
DBPASS=''   # Site Database Password

#########################################################################################

# Prints summarized Site status.
s_status() {
  local S=''
  local BW=''
  local BD=''

  if [ "${ST}" == '0' ]; then
    ST="${SA}"
  else
    ST="${SM}"
  fi

  local TMP=$((
    echo 'Type,Site,Backup,DB,Backup'

    for S in ${ST}; do
       s_info_get "${S}" 1
       BW=$(ls "${DBU}/${S}/${S}"-????????-????.tar.bz2 2>/dev/null | tail -n 1 | sed 's/.tar.bz2$//' | awk -F'-' '{print $(NF - 1)"-"$NF}')
       BD=$(ls "${DBU}/${S}/${DBNAME}"-????????-????.sql 2>/dev/null | tail -n 1 | sed 's/.sql$//' | awk -F'-' '{print $(NF - 1)"-"$NF}')

       echo " ${STYPE},${S},${BW},${DBNAME},${BD}"
    done
  ) | column -t -s, | sed -e '1 s/\(^.*$\)/\\e[93m\1\\e[39m/')

  echo -e "${TMP}"
  echo
}

# Prints version.
s_version() {
  pyel 'Version:'
  pnor "  ./${APP} ${VERSION} ~ ${CREATOR} ~ ${COPYRIGHT}" 1
}

# Shows the help text.
s_help() {
  pyel 'Usage:'
  pnor "  ./${APP}"' [options] [site1] [site2] [site3]'
  pnor
  pnor '  --config=file     Define Configuration file. Default .m.conf'
  pnor
  pnor '  -q, --quiet       Quiet, without output.'
  pnor '  -s, --status      Prints summarized Site status.'
  pnor '  -v, --version     Prints '"${APP}"' version.'
  pnor '  -h, --help        Shows this text.'
  pnor
  pnor '  -a, --all         Execute on all sites.'
  pnor '  -w, --www         Execute only WWW. It does not apply to rsync/FTP syncs.'
  pnor '  -d, --db          Execute only DB. It does not apply to rsync/FTP syncs.'
  pnor
  pnor '  -b, --backup      Backup operation. Default if nothing else is specified.'
  pnor '  -c, --clean       Delete Backup files that have same Hash. Keeps the oldest.'
  pnor '  -l, --list        Lists Backup files.'
  pnor '  -i, --info        Shows Site info.'
  pnor
  pnor '  -f, --ftp         Sync files to Remote rsync Server.'
  pnor '  -r, --rsync       Sync files to Remote FTP Server.'
  pnor
  pnor '  Only for Drupal:'
  pnor '  -u, --update      Update site code.'
  pnor '  -t, --truncate    Truncate Cache tables in MySQL.'
  pnor '  -0, --offline     Set Site Offline.'
  pnor '  -1, --online      Set Site Online.'
  pnor
  pyel 'Example:'
  pnor "  ./${APP}"' -bcwr site1.org site2.edu'
  pnor '    1) It will Backup only WWW.'
  pnor '    2) Then it will Clean-up at WWW.'
  pnor '    3) At the end it will sync Backup folder to Remote rsync Server.'
  pnor
}

# Backup Operation. Default if nothing else is specified.
# param 1: Site
s_backup() {
  if [ -d "${DWWW}/${1}" ]; then
    cd "${DWWW}"

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}"

    if [ "${OW}" == '1' ]; then
      if [ $(ls "${1}"-????????-????.tar.bz2.tmp 2>/dev/null | wc -l) != '0' ]; then
        if [ "${INCOMPLETEDELETE}" == '1' ]; then
          pnor '    Removing interrupted Backup files.'
          rm -f "${1}"-????????-????.tar.bz2.tmp
        else
          pnor '    Some interrupted Backup files found at '"${DWWW}."
        fi
      fi

      pnor '    Compressing to '"${1}-${DAY}"'.tar.bz2'
      tar cjf "${1}-${DAY}".tar.bz2.tmp "${1}/"
      mv "${1}-${DAY}".tar.bz2.tmp "${DBU}/${1}/${1}-${DAY}".tar.bz2
      sha256sum "${DBU}/${1}/${1}-${DAY}".tar.bz2 | head -c 64 > "${DBU}/${1}/${1}-${DAY}".tar.bz2.sha256
    fi

    if [ "${OD}" == '1' ]; then
      if [ ! -z "${DBNAME}" ]; then
        if [ $(ls "${DBU}/${1}/${DBNAME}"-????????-????.sql.tmp 2>/dev/null | wc -l) != '0' ]; then
          if [ "${INCOMPLETEDELETE}" == '1' ]; then
            pnor '    Removing interrupted Backup files.'
            rm -f "${DBU}/${1}/${DBNAME}"-????????-????.sql.tmp
          else
            pnor '    Some interrupted Backup files found at '"${DBU}."
          fi
        fi

        pnor '    Exporting database '"${DBNAME} to ${DBNAME}-${DAY}.sql"
        mysqldump ${MOPTS} --skip-dump-date --databases "${DBNAME}" > "${DBU}/${1}/${DBNAME}-${DAY}".sql.tmp

        mv "${DBU}/${1}/${DBNAME}-${DAY}".sql.tmp "${DBU}/${1}/${DBNAME}-${DAY}".sql
        sha256sum "${DBU}/${1}/${DBNAME}-${DAY}".sql | head -c 64 > "${DBU}/${1}/${DBNAME}-${DAY}".sql.sha256
      elif [ "${STYPE}" != 'O' ]; then
        pnor '    Failed to identify database.'
      fi
    fi

    pnor '    Operation completed.' 1
  fi
}

# Delete Backup files that have same Hash. Keeps the oldest.
# param 1: Site
s_clean() {
  if [ -d "${DBU}/${1}" ]; then
    cd "${DBU}/${1}"
    local C=0

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}" 1

    if [ "${OW}" == '1' ]; then
      pyel '  WWW Backups:'

      for S1 in $(ls "${1}"-????????-????.tar.bz2 2>/dev/null); do
        if [ -f "${S1}" ]; then
          for S2 in $(ls "${1}"-????????-????.tar.bz2 2>/dev/null | grep "${S1}" -v); do
            if [ $(diff "${S1}".sha256 "${S2}".sha256 | wc -l) == '0' ]; then
              rm -f "${S2}" "${S2}".sha256
              pnor "    ${S2}"' removed'
              ((C++))
            fi
          done
        fi
      done

      if [ "${C}" == '0' ]; then
        pnor '    (nothing removed)'
      fi

      pnor
    fi

    if [ "${OD}" == '1' ]; then
      if [ ! -z "${DBNAME}" ]; then
        pyel '  DB Backups:'

        C=0
        for S1 in $(ls "${DBNAME}"-????????-????.sql 2>/dev/null); do
          if [ -f "${S1}" ]; then
            for S2 in $(ls "${DBNAME}"-????????-????.sql 2>/dev/null | grep "${S1}" -v); do
              if [ $(diff "${S1}".sha256 "${S2}".sha256 | wc -l) == '0' ]; then
                rm -f "${S2}" "${S2}".sha256
                pnor "    ${S2}"' removed'
                ((C++))
              fi
            done
          fi
        done

        if [ "${C}" == '0' ]; then
          pnor '    (nothing removed)'
        fi

        pnor
      fi
    fi
  else
    pnor "${DBU}/${1}"' not found.' 1
  fi
}

# Lists Backup files.
# param 1: Site
s_list() {
  if [ -d "${DBU}/${1}" ]; then
    cd "${DBU}/${1}"

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}" 1

    if [ "${OW}" == '1' ]; then
      pyel '  WWW Backups:'
      ls "${1}"-????????-????.tar.bz2 2>/dev/null | awk '{print "    "$1;}'
      pnor
    fi

    if [ "${OD}" == '1' ]; then
      if [ ! -z "${DBNAME}" ]; then
        pyel '  DB Backups:'
        ls "${DBNAME}"-????????-????.sql 2>/dev/null | awk '{print "    "$1;}'
        pnor
      fi
    fi
  else
    pnor "${DBU}/${1}"' not found.' 1
  fi
}

# Shows Site info.
# param 1: Site
s_info() {
  s_info_get "${1}" 1 1

  pyel 'Site:'
  pnor "  ${1}" 1

  case "${STYPE}" in

    D7)
      pnor '  Type:     Drupal 7'
      ;;

    W4)
      pnor '  Type:     Wordpress 4'
      ;;

    J)
      pnor '  Type:     Joomla 2/3'
      ;;

    O)
      pnor '  Type:     Other'
      ;;

  esac

  if [ ! -z "${SVERSION}" ]; then
    pnor '  Version:  '"${SVERSION}"
  fi

  if [ ! -z "${DBNAME}" ]; then
    pnor '  Database: '"${DBNAME}"
    pnor '  Username: '"${DBUSER}"
    pnor '  Password: '"${DBPASS}"
  fi

  pnor
}

# Gets Site info.
# param 1: Site
# param 2: If 1, write them to disk
# paran 3: If 1, force reading again
s_info_get() {
  local TMP=''
  local C=0

  STYPE=''
  SVERSION=''
  DBNAME=''
  DBUSER=''
  DBPASS=''

  if [ ! -z "${3}" ]; then
    if [ "${3}" == '1' ]; then
      C=1
    fi
  fi

  if [ -f "${DBU}/${1}/${1}".info ] && [ "${C}" == '0' ]; then
    TMP=$(cat "${DBU}/${1}/${1}".info)
    STYPE=$(echo "${TMP}" | grep '^STYPE=.' | tail -n 1 | sed 's/^STYPE=//')
    SVERSION=$(echo "${TMP}" | grep '^SVERSION=.' | tail -n 1 | sed 's/^SVERSION=//')
    DBNAME=$(echo "${TMP}" | grep '^DBNAME=.' | tail -n 1 | sed 's/^DBNAME=//')
    DBUSER=$(echo "${TMP}" | grep '^DBUSER=.' | tail -n 1 | sed 's/^DBUSER=//')
    DBPASS=$(echo "${TMP}" | grep '^DBPASS=.' | tail -n 1 | sed 's/^DBPASS=//')
  elif [ -d "${DWWW}/${1}" ]; then
    if [ -f "${DWWW}/${1}/${CD7}" ]; then
      STYPE='D7'
      TMP=`php -r "include('${DWWW}/${1}/${CD7}'); print \\$databases['default']['default']['database'] . \"\\n\" . \\$databases['default']['default']['username'] . \"\\n\" . \\$databases['default']['default']['password'];"`

      if [ -f "${DWWW}/${1}/${VD7}" ]; then
        TMP+=$'\n'$(grep "define('VERSION'" "${DWWW}/${1}/${VD7}" | awk -F"'" '{print $4}')
      fi
    elif [ -f "${DWWW}/${1}/${CW4}" ]; then
      STYPE='W4'
      TMP=$(grep 'DB_NAME\|DB_USER\|DB_PASSWORD' "${DWWW}/${1}/${CW4}")
      TMP=`php -r "${TMP} echo DB_NAME . \"\\n\" . DB_USER . \"\\n\" . DB_PASSWORD;"`

      if [ -f "${DWWW}/${1}/${VW4}" ]; then
        TMP+=$'\n'$(php -r "include('${DWWW}/${1}/${VW4}'); echo \$wp_version;")
      fi
    elif [ -f "${DWWW}/${1}/${CJ}" ]; then
      STYPE='J'
      TMP=$(grep '$db\|$user\|$password' "${DWWW}/${1}/${CJ}" | sed 's/public\(\ \)\+\$/\$/g')
      TMP=`php -r "${TMP} echo \\$db . \"\\n\" . \\$user . \"\\n\" . \\$password;"`

      if [ -f "${DWWW}/${1}/${VJ}" ]; then
        TMP+=$'\n'$(grep '<version>' "${DWWW}/${1}/${VJ}" | awk -F'>||<' '{print $3}')
      fi
    else
      STYPE='O'
      TMP=''
    fi

    DBNAME=$(echo "${TMP}" | sed -n '1p')
    DBUSER=$(echo "${TMP}" | sed -n '2p')
    DBPASS=$(echo "${TMP}" | sed -n '3p')
    SVERSION=$(echo "${TMP}" | sed -n '4p')

    if [ ! -z "${2}" ]; then
      if [ "${2}" == '1' ]; then
        s_info_set "${1}"
      fi
    fi
  fi
}

# Sets Site info.
# param 1: Site
s_info_set() {
  mkdir -p "${DBU}/${1}"

  if [ ! -z "${STYPE}" ]; then
    echo 'STYPE='"${STYPE}" > "${DBU}/${1}/${1}".info

    if [ ! -z "${SVERSION}" ]; then
      echo 'SVERSION='"${SVERSION}" >> "${DBU}/${1}/${1}".info
    fi

    if [ "${STYPE}" != 'O' ]; then
      echo 'DBNAME='"${DBNAME}" >> "${DBU}/${1}/${1}".info
      echo 'DBUSER='"${DBUSER}" >> "${DBU}/${1}/${1}".info
      echo 'DBPASS='"${DBPASS}" >> "${DBU}/${1}/${1}".info
    fi
  fi
}

# Sync files to Remote rsync Server.
# param 1: Site
s_rsync() {
  if [ -d "${DBU}/${1}" ]; then
    pyel 'Site:'
    pnor "  ${1}" 1

    local OPT1=''
    local OPT2=''

    if [ "${OQ}" == '0' ]; then
      OPT1+='v'
    fi

    if [ "${KEEPFILES}" == '0' ]; then
      OPT2+=' --remove-source-files'
    fi

    rsync -a${OPT1}ze "ssh -i ${RKEY} -p ${RPORT}" ${OPT2} "${DBU}/${1}" "${RUSER}@${RHOST}:${RPATH}"
  else
    pnor "${DBU}/${1}"' not found.'
  fi
}

# Sync files to Remote FTP Server.
# param 1: Site
s_ftp() {
  if [ -d "${DBU}/${1}" ]; then
    pyel 'Site:'
    pnor "  ${1}" 1

    local OPT1='mirror --reverse'

    if [ "${OQ}" == '0' ]; then
      OPT1+=' --verbose'
    fi

    if [ "${KEEPFILES}" == '0' ]; then
      OPT1+=' --delete'
    fi

    lftp -u "${FUSER},${FPASS}" -e "${OPT1} ${DBU}/${1} ${FPATH}/${1}; quit" ${FHOST} -p ${FPORT}
  else
    pnor "${DBU}/${1}"' not found.'
  fi
}

# Update site.
# param 1: Site
s_update() {
  if [ -d "${DWWW}/${1}" ]; then
    local RES='0'
    local V=''

    cd "${DWWW}"

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}" 1

    case "${STYPE}" in

      D7)
        V=$(wget -qO- 'https://www.drupal.org/node/3060/release/feed?api_version[0]=103' | grep '<title>drupal' | head -n1 | awk -F'>||<' '{print $3}' | awk '{print $2}')

        if [ ! -z "${V}" ]; then
          if [ "${V}" != "${SVERSION}" ]; then
            pnor '  Latest version '"${V} vs ${SVERSION}"' found. Upgrading.'

            pnor '  Downloading '"https://ftp.drupal.org/files/projects/drupal-${V}.tar.gz"
            wget -q "https://ftp.drupal.org/files/projects/drupal-${V}.tar.gz"

            if [ -a "${DWWW}/drupal-${V}.tar.gz" ]; then
              pnor '  Decompressing '"drupal-${V}.tar.gz to drupal-${V}"
              tar zxf "drupal-${V}.tar.gz"

              if [ -d "${DWWW}/drupal-${V}" ]; then
                if [ "${O0}" == '0' ]; then
                  RES=$(s_onoffline_run '2')
                fi

                if [ "${RES}" == '2' ] || [ "${O0}" == '1' ]; then
                  pnor '  Site is set offline.'

                  pnor '  Removing unwanted files.'
                  find "${DWWW}/drupal-${V}/" -name 'README.txt' -delete
                  rm -rf drupal-${V}.tar.gz drupal-${V}/install.php drupal-${V}/sites drupal-${V}/C* drupal-${V}/.e* drupal-${V}/.g* drupal-${V}/I* drupal-${V}/L* drupal-${V}/M* drupal-${V}/U*

                  if [ $(ls "${DWWW}/drupal-${V}" 2> /dev/null | grep 'sites' -c) == '0' ]; then
                    pnor '  Fixing file and directory permissions.'
                    chown ${UWWW}:root ${DWWW}/drupal-${V}/* .htaccess -R
                    chmod 0460 ${DWWW}/drupal-${V}/* .htaccess -R
                    find "${DWWW}/drupal-${V}/" -type d | xargs chmod 0570

                    for F in $(ls "${DWWW}/drupal-${V}"); do
                      if [ ! -z "${F}" ]; then
                        if [ $(ls "${DWWW}/${1}" 2> /dev/null | grep "${F}" -c) == '1' ]; then
                          rm -rf "${DWWW}/${1}/${F}"
                          cp "${DWWW}/drupal-${V}/${F}" "${DWWW}/${1}/" -R --preserve=all
                        fi
                      fi
                    done

                    rm -rf "${DWWW}/drupal-${V}"

                    RES='0'

                    if [ "${O0}" == '0' ]; then
                      RES=$(s_onoffline_run '1')

                      if [ "${RES}" == '1' ]; then
                        pnor '  Site is set online.'
                      fi
                    fi

                    if [ "${RES}" == '1' ] || [ "${O0}" == '1' ]; then
                      pnor '  Please visit http://'"${1}"'/update.php to continue the update procedure.'
                    fi
                  fi
                fi
              fi
            fi
          else
            pnor '  Latest version found. Not upgrading.'
          fi
        fi
        ;;

    esac

    pnor
  fi
}

# Set Online site and print messages
# param 1: Site
s_online() {
  s_onoffline "${1}" '1'
}

# Set Offline site and print messages
# param 1: Site
s_offline() {
  s_onoffline "${1}" '2'
}

# Set Online / Offline site and print messages
# param 1: Site
# param 2: 1 for Online / 2 for Offline
s_onoffline() {
  if [ ! -z "${DBNAME}" ]; then
    local RES=''

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}" 1

    case "${STYPE}" in

      D7)
        RES=$(s_onoffline_run "${2}")

        if [ "${RES}" == '1' ]; then
          pnor '  Site is Online.'
        elif [ "${RES}" == '2' ]; then
          pnor '  Site is Offline.'
        fi
        ;;

    esac

    pnor
  fi
}

# Set Online / Offline site
# param 1: 1 for Online / 2 for Offline
s_onoffline_run() {
  local RES=''

  case "${STYPE}" in

    D7)
      if [ "${1}" == '1' ]; then
        RES=$(s_mysqlcmd "${DBNAME}" "UPDATE variable SET value='i:0;' WHERE name='maintenance_mode'")
      elif [ "${1}" == '2' ]; then
        RES=$(s_mysqlcmd "${DBNAME}" "UPDATE variable SET value='i:1;' WHERE name='maintenance_mode'")
      fi

      RES=$(s_truncatecache_run)
      RES=$(s_mysqlcmd "${DBNAME}" "SELECT value FROM variable WHERE name='maintenance_mode'")
      ;;

  esac

  if [ ! -z "${RES}" ]; then
    if [ "${RES}" == 'i:0;' ]; then
      echo '1'
    elif [ "${RES}" == 'i:1;' ]; then
      echo '2'
    fi
  fi
}

# Truncate SQL Cache and print messages
# param 1: Site
s_truncatecache() {
  if [ ! -z "${DBNAME}" ]; then
    local RES=''

    pyel 'Site:'
    pnor "  ${1}  ${DBNAME}" 1

    case "${STYPE}" in

      D7)
        pnor '  Clearing Cache.'
        RES=$(s_truncatecache_run)

        if [ "${RES}" == '1' ]; then
          pnor '  Cache cleared.'
        else
          pnor '  Failed to clear Cache.'
        fi
        ;;

    esac

    pnor
  fi
}

# Truncate SQL Cache Tables
s_truncatecache_run() {
  local RES=''

  case "${STYPE}" in

    D7)
      RES=$(s_mysqlcmd "${DBNAME}" "SELECT DISTINCT CONCAT('TRUNCATE TABLE ', TABLE_SCHEMA, '.', TABLE_NAME, ';') FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='${DBNAME}' AND (TABLE_NAME='cache' OR TABLE_NAME LIKE 'cache_%');")
      RES=$(s_mysqlcmd "${DBNAME}" "${RES}")

      RES=$(s_mysqlcmd "${DBNAME}" "SELECT DISTINCT CONCAT('SELECT COUNT(*) FROM ', TABLE_SCHEMA, '.', TABLE_NAME, ';') FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='${DBNAME}' AND (TABLE_NAME='cache' OR TABLE_NAME LIKE 'cache_%');")
      RES=$(s_mysqlcmd "${DBNAME}" "${RES}")
      ;;

  esac

  if [ ! -z "${RES}" ]; then
    if [ $(echo "${RES}" | grep '^0$' -vc) == '0' ]; then
      echo '1'
    fi
  fi
}

# Executes commands on current MySQL database.
# param 1: Database
# param 2: MySQL command
s_mysqlcmd() {
  if [ "${MEN}" == '1' ]; then
    if [ ! -z "${1}" ]; then
      if [ ! -z "${2}" ]; then
        mysql ${MOPTS} -D "${1}" -Nsre "${2}"
      fi
    fi
  fi
}

# Prints normal text.
# param 1: payload
# param 2: If 1, add newline
# param 3: If 1, outputs at stderr >&2
pnor() {
  if [ "${OQ}" == '0' ]; then
    echo "${1}"

    if [ ! -z "${2}" ]; then
      if [ "${2}" == '1' ]; then
        echo
      fi
    fi
  fi
}

# Prints everything Yellow!
# param 1: payload
# param 2: If 1, add newline
# param 3: If 1, outputs at stderr >&2
pyel() {
  if [ "${OQ}" == '0' ]; then

    local YEL='\e[93m'
    local NOR='\e[39m'

    echo -e "${YEL}${1}${NOR}"

    if [ ! -z "${2}" ]; then
      if [ "${2}" == '1' ]; then
        echo
      fi
    fi
  fi
}

#########################################################################################

for OPT in ${OPTS}; do
  declare $(echo "${OPT}" | awk -F'|' '{print $1}')='0'
done

if [ ! -z "${1}" ]; then
  ST=''
  TMP=''

  while [ ! -z "${1}" ]; do
    OO=''

    if [ "${1:0:2}" == '--' ]; then
      OO="${1:2}"
    elif [ "${1:0:1}" == '-' ]; then
      OO=$(echo "${1:1}" | sed 's/\(.\)/\1\n/g' | grep '^$' -v | sort -u)
    else
      ST+="${1}"$'\n'
    fi

    if [ ! -z "${OO}" ]; then
      for O in ${OO}; do
        if [ $(echo "${O}" | grep '=' -c) == 0 ]; then
          declare $(echo "${OPTS}" | grep "|${O}|" | awk -F'|' '{print $1}')='1'
        else
          TMP=$(echo "${O}" | awk -F'=' '{print $2}')
          O=$(echo "${O}" | awk -F'=' '{print $1}')
          declare $(echo "${OPTS}" | grep "|${O}|" | awk -F'|' '{print $1}')="${TMP}"
        fi
      done
    fi

    shift
  done

  OO='1'

  if [ "${OC}" == '0' ] && [ "${OL}" == '0' ] && [ "${OI}" == '0' ] && [ "${OF}" == '0' ] && [ "${OR}" == '0' ] && [ "${OU}" == '0' ] && [ "${OT}" == '0' ] && [ "${O0}" == '0' ] && [ "${O1}" == '0' ]; then
    OB='1'
  fi

  if [ "${OW}" == '0' ] && [ "${OD}" == '0' ]; then
    OW='1'
    OD='1'
  fi
fi

#if [ -z "${PS1}" ]; then
#  OQ='1'
#fi

DAY=$(date +%Y%m%d-%H%M)
SOURCE=$(echo "${BASH_SOURCE[0]}" | sed "s/\/${APP}//")

if [ ! -z "${OM}" ] && [ "${OM}" != '0' ]; then
  SETTINGS="${OM}"
fi

if [ -a "${SETTINGS}" ]; then
  source "${SETTINGS}"
elif [ -a "${SOURCE}/${SETTINGS}" ]; then
  SETTINGS="${SOURCE}/${SETTINGS}"

  source "${SETTINGS}"
fi

pnor

if [ ! -d "${DWWW}" ]; then
  pyel 'DWWW is not valid directory. Specify WWW Directory to continue.' 1 1
  exit 1
elif [ $(ls "${DWWW}" | wc -l) == '0' ]; then
  pyel 'Warning: DWWW directory is empty.' 1 1

  if [ $(ls "${DBU}" | wc -l) == '0' ]; then
    pyel 'Warning: DBU directory is empty too.' 1 1

    exit 1
  fi

  OB='0'
  OR='0'
  OF='0'
  MEN='0'
fi

if [ ! -d "${DBU}" ]; then
  pyel 'DBU is not valid directory. Specify Backup Directory to continue.' 1 1
  exit 1
elif [ "${DWWW}" == "${DBU}" ]; then
  pyel 'Warning: DBU directory is same with DWWW directory.' 1 1

  exit 1
fi

if [ "${MEN}" == '1' ]; then
  if [ $(mysqladmin --version 2>/dev/null | grep Distrib -c) == '1' ]; then
    if [ $(mysqladmin --version 2>/dev/null | grep MariaDB -c) == '0' ]; then
      MLOGINPATH="${SOURCE}"'/.mysql-'"${MHOST}-${MUSER}"'.cnf'
      echo '[client]'             > "${MLOGINPATH}"
      echo 'user='"${MUSER}"     >> "${MLOGINPATH}"
      echo 'password='"${MPASS}" >> "${MLOGINPATH}"
      echo 'host='"${MHOST}"     >> "${MLOGINPATH}"

      MOPTS="--login-path=${MLOGINPATH}"
    else
      MOPTS="--user=${MUSER} --password=${MPASS} --host=${MHOST}"
    fi

    if [ -z "${MUSER}" ]; then
      pyel 'MUSER is empty. Specify MySQL User (maybe root?) to activate MySQL Backups and Updates.' 1 1
      MEN='0'
    elif [ -z "${MHOST}" ]; then
      pyel 'MHOST is empty. Specify MySQL Host (maybe localhost?) to activate rsync Backups and Updates.' 1 1
      MEN='0'
    elif [ $(mysqladmin ${MOPTS} ping 2>/dev/null | grep 'mysqld is alive' -c) == '0' ]; then
      pyel 'Cannot establish connection to MySQL. Please check hostname and credentials to activate MySQL Backups and Updates.' 1 1
      MEN='0'
    fi
  else
    pyel 'MySQL client is not installed. Please instal MySQL client to activate MySQL Backups and Updates.' 1 1
    MEN='0'
  fi
fi

if [ "${MEN}" == '0' ]; then
  OD='0'
  OU='0'
  OT='0'
  ON='0'
fi

if [ "${OU}" == '1' ]; then
  if [ $(wget -V 2> /dev/null | wc -l) == '0' ]; then
    pyel 'wget is not installed. Install it (maybe apt-get install wget ?) to activate Updates.' 1 1
    OU='0'
  fi
fi

if [ "${OR}" == '1' ]; then
  if [ $(rsync --version 2> /dev/null | wc -l) == '0' ]; then
    pyel 'rsync is not installed. Install it (maybe apt-get install rsync?) to activate rsync Backups.' 1 1
    OR='0'
  elif [ -z "${RUSER}" ]; then
    pyel 'RUSER is empty. Specify SSH User (maybe root?) to activate rsync Backups.' 1 1
    OR='0'
  elif [ ! -f "${RKEY}" ]; then
    pyel 'RKEY is not valid file. Specify SSH Key (maybe $HOME/.ssh/id_rsa?) to activate rsync Backups.' 1 1
    OR='0'
  elif [ -z "${RHOST}" ]; then
    pyel 'RHOST is empty. Specify rsync Host to activate rsync Backups.' 1 1
    OR='0'
  elif [ -z "${RPORT}" ]; then
    pyel 'RPORT is empty. Specify SSH Port (maybe 22?) to activate rsync Backups.' 1 1
    OR='0'
  elif [ -z "${RPATH}" ]; then
    pyel 'RPATH is empty. Specify rsync Path (maybe ~ ?) to activate rsync Backups.' 1 1
    OR='0'
#  elif [ $(ssh -i "${RKEY}" -q "${RUSER}@${RHOST}" -p ${RPORT} exit; echo $?) != '0' ]; then
#    pyel 'rsync credentials are wrong. Update them to activate rsync Backups.' 1 1
#    OR='0'
  fi
fi

if [ "${OF}" == '1' ]; then
  if [ $(lftp -v 2> /dev/null | wc -l) == '0' ]; then
    pyel 'lftp is not installed. Install it (maybe apt-get install lftp ?) to activate FTP Backups.' 1 1
    OF='0'
  elif [ -z "${FUSER}" ]; then
    pyel 'FUSER is empty. Specify FTP User to activate FTP Backups.' 1 1
    OF='0'
  elif [ -z "${FHOST}" ]; then
    pyel 'FHOST is empty. Specify FTP Host to activate FTP Backups.' 1 1
    OF='0'
  elif [ -z "${FPORT}" ]; then
    pyel 'FPORT is empty. Specify FTP Port (maybe 21?) to activate FTP Backups.' 1 1
    OF='0'
  elif [ -z "${FPATH}" ]; then
    pyel 'FPATH is empty. Specify FTP Path (maybe ~ ?) to activate FTP Backups.' 1 1
    OF='0'
  elif [ $(lftp -c "open -u ${FUSER},${FPASS} -p ${FPORT} ${FHOST}; ls -a" 2> /dev/null | wc -l) == '0' ]; then
    pyel 'FTP credentials are wrong. Update them to activate FTP Backups.' 1 1
    OF='0'
  fi
fi

for S in $(ls "${DWWW}"/*/ "${DBU}"/*/ -d 2>/dev/null | awk -F'/' '{print $(NF-1)}' | sort | uniq); do
  if [ $(echo ",${IGNORE}," | grep ",${S}," -c) == '0' ]; then
    SA+="${S}"$'\n'
  fi
done

if [ -z "${OO}" ]; then
  if [ "${OQ}" == '0' ]; then
    s_status
  fi

  exit 0
fi

for S in ${ST}; do
  if [ $(echo "${SA}" | grep "${S}" -c) != '0' ]; then
    SM+="${S}"$'\n'
  fi
done

if [ "${OA}" == '1' ]; then
  SM="${SA}"
fi

ST=$(echo "${SM}" | grep '^$' -v | wc -l)

if [ "${OS}" == '1' ] || [ "${OV}" == '1' ] || [ "${OH}" == '1' ]; then
  if [ "${OQ}" == '0' ]; then
    if [ "${OS}" == '1' ]; then
      s_status
    fi

    if [ "${OV}" == '1' ]; then
      s_version
    fi

    if [ "${OH}" == '1' ]; then
      s_help
    fi
  fi

  exit 0
fi

OO='0'

for O in ${OPTSO}; do
  O=$(echo "${OPTS}" | grep "^${O}|" | awk -F'|' '{print $1}')

  if [ "${!O}" == '1' ]; then
    O=$(echo "${OPTS}" | grep "^${O}|" | awk -F'|' '{print $NF}')

    if [ "${OO}" == '0' ]; then
      OO='1'

      for S in ${SM}; do
        s_info_get "${S}" '1'
      done
    fi

    for S in ${SM}; do
      s_info_get "${S}"
      "${O}" "${S}"
    done
  fi
done

exit 0
