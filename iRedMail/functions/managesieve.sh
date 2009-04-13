#!/bin/sh

# Author:   Zhang Huangbin <michaelbibby (at) gmail.com>

# Configure pysieved.
pysieved_config()
{
    ECHO_INFO "==================== Pysieved ===================="

    backup_file ${PYSIEVED_INI}

    ECHO_INFO "Setting up managesieve server: pysieved."

    cat > ${PYSIEVED_INI} <<EOF
${CONF_MSG}
[main]
# Authentication back-end to use
auth    = Dovecot

# User DB back-end to use
userdb  = Virtual

# Storage back-end to use
storage = Dovecot

# Bind to what address?  (Ignored with --stdin)
bindaddr = ${PYSIEVED_BINDADDR}

# Listen on what port?  (Ignored with --stdin)
port    = ${PYSIEVED_PORT}

# Write a pidfile here
pidfile = ${PYSIEVED_PIDFILE}

[Virtual]
# Append username to this for home directories
base = ${SIEVE_DIR}

# What UID and GID should own all files?  -1 to not bother
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}

# Switch user@host.name to host.name/user?
hostdirs = True

[Dovecot]
# Path to Dovecot's auth socket (do not set unless you're using
# Dovecot auth)
mux = ${DOVECOT_SOCKET_MUX}

# Path to Dovecot's master socket (if using Dovecot userdb lookup)
master = ${DOVECOT_SOCKET_MASTER}

# Path to sievec
sievec = ${DOVECOT_SIEVEC}

# Where in user directory to store scripts
scripts = ${PYSIEVED_RULE_DIR}

# Filename used for the active SIEVE filter (see README.Dovecot)
active = ${SIEVE_RULE_FILENAME}

# What user/group owns the mail storage (-1 to never setuid/setgid)
uid = ${VMAIL_USER_UID}
gid = ${VMAIL_USER_GID}
EOF

    # Modify pysieved source, replace 'os.mkdir' by 'os.makedirs'.
    pysieved_dovecot_py="$(eval ${LIST_FILES_IN_PKG} pysieved|grep 'dovecot.py$')"
    [ ! -z ${pysieved_dovecot_py} ] && perl -pi -e 's#os.mkdir#os.makedirs#' ${pysieved_dovecot_py}

    # Create directory to store pid file.
    pysieved_pid_dir="$(dirname ${PYSIEVED_PIDFILE})"
    mkdir -p ${pysieved_pid_dir} 2>/dev/null
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${pysieved_pid_dir}

    # Copy init script and enable it.
    cp -f ${SAMPLE_DIR}/pysieved.init /etc/init.d/pysieved
    chmod +x /etc/init.d/pysieved
    /sbin/chkconfig --level 345 pysieved on

    # Disable pysieved in xinetd.
    pysieved_xinetd_conf="$(eval ${LIST_FILES_IN_PKG} pysieved | grep 'xinetd' | grep 'pysieved$')"
    [ ! -z ${pysieved_xinetd_conf} ] && perl -pi -e 's#(.*disable.*=).*#${1} yes#' ${pysieved_xinetd_conf}

    cat >> ${TIP_FILE} <<EOF
pysieved:
    * Configuration files:
        - ${PYSIEVED_INI}
    * RC script:
        - /etc/init.d/pysieved

EOF

    echo 'export status_pysieved_config="DONE"' >> ${STATUS_FILE}
}

managesieve_config()
{
    if [ X"${USE_MANAGESIEVE}" == X"YES" ]; then
        # Use pysieved.
        if [ X"${USE_PYSIEVED}" == X"YES" ]; then
            check_status_before_run pysieved_config
        else
            :
        fi
    else
        :
    fi
}
