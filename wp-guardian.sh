#!/bin/bash
#set -x

# Author: Krzysztof Luczak
#

renice -n 19 $$
ionice -c3 -p$$

SECONDS=0 # measure time
LC_ALL=C # speed up grep

### ---------------------------------------------------------------------------
###                              KONFIGURACJA
### ---------------------------------------------------------------------------

ALERT_EMAIL="email@domena.pl" # adres email, na ktory wysylane beda powiadomienia

WEBSITE_HOME_DIR="/katalog/strony/internetowej/" # katalog strony internetowej

PHP_CLI="/usr/bin/php"

WP_CLI="/usr/local/bin/wp-cli" # sciezka do programu wp-cli

DATA_DIR="${WEBSITE_HOME_DIR}/.wp-guardian" # katalog roboczy dla skryptu - ZMIANA NIE ZALECANA

WP_CLI_OPTIONS="--path=${WEBSITE_HOME_DIR} --skip-plugins --skip-themes --skip-packages"

SHA256SUM_BIN="/usr/bin/sha256sum"

AWK_BIN="/usr/bin/awk"

ALERT_FILE="${DATA_DIR}/alert.log"
true >"$ALERT_FILE"

ERROR_FILE="${DATA_DIR}/error.log"

### ---------------------------------------------------------------------------
###                              FUNKCJE
### ---------------------------------------------------------------------------

function check_plugin_update()
{
    local file="plugins.txt"
    local tmp_file="plugins.tmp"

    local command="$PHP_CLI $WP_CLI plugin list --format=csv $WP_CLI_OPTIONS > ${DATA_DIR}/${tmp_file} 2>> ${ERROR_FILE}"
    eval "$command"

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety

        echo -e "\n--- WTYCZKI --- pierwszy raport"     >> "$ALERT_FILE"
        cat "${DATA_DIR}/${tmp_file}" | column -t -s',' >> "$ALERT_FILE"
    else
        cmp -s "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
        if [ $? -ne 0 ]
        then
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- WTYCZKI ---"                                 >> "$ALERT_FILE"
            echo "Zmiana:"                                              >> "$ALERT_FILE"
            grep -vf "${DATA_DIR}/${file}" "${DATA_DIR}/${tmp_file}" | column -t -s','  >> "$ALERT_FILE"
        fi
    fi
    # aktualizacja
    mv -f "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
}


function check_theme_update()
{
    local file="themes.txt"
    local tmp_file="themes.tmp"


    local command="$PHP_CLI $WP_CLI theme list --format=csv $WP_CLI_OPTIONS > ${DATA_DIR}/${tmp_file} 2>> ${ERROR_FILE}"
    eval "$command"


    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety

        echo -e "\n--- MOTYWY --- pierwszy raport"      >> "$ALERT_FILE"
        cat "${DATA_DIR}/${tmp_file}" | column -t -s',' >> "$ALERT_FILE"
    else
        cmp -s "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
        if [ $? -ne 0 ]
        then
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- MOTYWY ---"                  >> "$ALERT_FILE"
            echo "Poprzednio:"                          >> "$ALERT_FILE"
            cat "${DATA_DIR}/${file}" | column -t -s',' >> "$ALERT_FILE"
            echo "Aktualnie: "                          >> "$ALERT_FILE"
            cat "${DATA_DIR}/${tmp_file}"               >> "$ALERT_FILE"
        fi
    fi
    # aktualizacja
    mv -f "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
}


function check_core_update()
{
    local file="core_update.txt"
    local tmp_file="core_update.tmp"

    local command="$PHP_CLI $WP_CLI core check-update $WP_CLI_OPTIONS --fields="version,package_url" \
    | tail -n +2 > ${DATA_DIR}/${tmp_file} 2>> ${ERROR_FILE}"
    eval "$command"

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo -e "\n--- Aktualizacja WordPressa --- pierwszy raport" >> "$ALERT_FILE"
        cat "${DATA_DIR}/${tmp_file}" | column -t -s','             >> "$ALERT_FILE"
    else
        cmp -s "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
        if [ $? -ne 0 ]
        then
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- Aktualizacja WordPressa ---"     >> "$ALERT_FILE"
            echo "Poprzednio:"                              >> "$ALERT_FILE"
            cat "${DATA_DIR}/${file}" | column -t -s','     >> "$ALERT_FILE"
            echo "Aktualnie: "                              >> "$ALERT_FILE"
            cat "${DATA_DIR}/${tmp_file}" | column -t -s',' >> "$ALERT_FILE"
        fi
    fi
    # aktualizacja
    mv -f "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
}


function check_core_verify_checksums()
{
    local file="core_checksums.txt"
    local tmp_file="core_checksums.tmp"

    local command="$PHP_CLI $WP_CLI core verify-checksums $WP_CLI_OPTIONS 2>&1 | grep -i warning > ${DATA_DIR}/${tmp_file}"
    eval "$command"

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo -e "\n--- Kontrola spojnosci plikow WordPressa --- pierwszy raport" >> "$ALERT_FILE"
        cat "${DATA_DIR}/${tmp_file}"                                            >> "$ALERT_FILE"
    else
        cmp -s "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
        if [ $? -ne 0 ]
        then
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- Kontrola spojnosci plikow WordPressa ---" >> "$ALERT_FILE"
            echo "Poprzednio:"                                       >> "$ALERT_FILE"
            cat "${DATA_DIR}/${file}"                                >> "$ALERT_FILE"
            echo "Aktualnie: "                                       >> "$ALERT_FILE"
            cat "${DATA_DIR}/${tmp_file}"                            >> "$ALERT_FILE"
        fi
    fi
    # aktualizacja
    mv -f "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
}


function check_user_modifications()
{
    local file="users.txt"
    local tmp_file="users.tmp"
    local command="$PHP_CLI $WP_CLI user list --format=csv $WP_CLI_OPTIONS > ${DATA_DIR}/${tmp_file} 2>> ${ERROR_FILE}"
    eval "$command"

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo -e "\n--- Uzytkownicy --- pierwszy raport" >> "$ALERT_FILE"
        cat "${DATA_DIR}/${tmp_file}" | column -t -s',' >> "$ALERT_FILE"
    else
        cmp -s "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
        if [ $? -ne 0 ]
        then
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- Uzytkownicy ---"                 >> "$ALERT_FILE"
            echo "Poprzednio:"                              >> "$ALERT_FILE"
            cat "${DATA_DIR}/${file}" | column -t -s','     >> "$ALERT_FILE"
            echo "Aktualnie: "                              >> "$ALERT_FILE"
            cat "${DATA_DIR}/${tmp_file}" | column -t -s',' >> "$ALERT_FILE"
        fi
    fi
    # aktualizacja
    mv -f "${DATA_DIR}/${tmp_file}" "${DATA_DIR}/${file}"
}


function check_file_htaccess()
{
    local file="htaccess.txt"
    local timestamp=`date '+%Y-%m-%d %H:%M:%S'`

    if [ ! -f "${WEBSITE_HOME_DIR}/.htaccess" ]
    then
        echo ".htaccess nie istnieje"
        return
    fi

    local command="$SHA256SUM_BIN ${WEBSITE_HOME_DIR}/.htaccess 2>> ${ERROR_FILE} | "$AWK_BIN" '{print \$1}'"
    local sum=`eval "$command"`

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo "${timestamp} ${sum}" > "${DATA_DIR}/${file}"
        echo -e "\n--- .htaccess zmieniony ---" >> "$ALERT_FILE"
    else
        local last=`tail -1 "${DATA_DIR}/${file}" | "$AWK_BIN" '{print $3}'`

        if [ "$last" != "$sum" ]
        then
            echo "${timestamp} ${sum}" >> "${DATA_DIR}/${file}"
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- .htaccess zmieniony ---" >> "$ALERT_FILE"
        fi
    fi
}

function check_file_wp_config()
{
    local file="wp_config.txt"
    local timestamp=`date '+%Y-%m-%d %H:%M:%S'`

    local command="$SHA256SUM_BIN ${WEBSITE_HOME_DIR}/wp-config.php 2>> ${ERROR_FILE} | "$AWK_BIN" '{print \$1}'"
    local sum=`eval "$command"`

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo "${timestamp} ${sum}" > "${DATA_DIR}/${file}"
        echo -e "\n--- wp-config.php zmieniony ---" >> "$ALERT_FILE"
    else
        local last=`tail -1 "${DATA_DIR}/${file}" | "$AWK_BIN" '{print $3}'`

        if [ "$last" != "$sum" ]
        then
            echo "${timestamp} ${sum}" >> "${DATA_DIR}/${file}"
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- wp-config.php zmieniony ---" >> "$ALERT_FILE"
        fi
    fi
}

function check_file_index()
{
    local file="index.txt"
    local timestamp=`date '+%Y-%m-%d %H:%M:%S'`

    local command="$SHA256SUM_BIN ${WEBSITE_HOME_DIR}/index.php 2>> ${ERROR_FILE} | "$AWK_BIN" '{print \$1}'"
    local sum=`eval "$command"`

    if [ ! -f "${DATA_DIR}/${file}" ]
    then
        # pierwsze uruchomienie lub plik zostal usuniety
        echo "${timestamp} ${sum}" > "${DATA_DIR}/${file}"
        echo -e "\n--- index.php zmieniony ---"  >> "$ALERT_FILE"
    else
        local last=`tail -1 "${DATA_DIR}/${file}" | "$AWK_BIN" '{print $3}'`

        if [ "$last" != "$sum" ]
        then
            echo "${timestamp} ${sum}" >> "${DATA_DIR}/${file}"
            # pliki sie roznia - byla zmiana !!!
            echo -e "\n--- index.php zmieniony ---" >> "$ALERT_FILE"
        fi
    fi
}

function simple_scan()
{
    local scan_file="scan.log"
    rm -f "${DATA_DIR}/${scan_file}"

    grep -RlF '\x47\x4c\x4fB\x41\x4c\x53' "$WEBSITE_HOME_DIR" | grep -vF "${DATA_DIR}" >> "${DATA_DIR}/${scan_file}" 2> /dev/null
    grep -RlF '\x47L\x4f\x42' "$WEBSITE_HOME_DIR" | grep -vF "${DATA_DIR}" >> "${DATA_DIR}/${scan_file}" 2> /dev/null
    grep -RlF '@include '\' "$WEBSITE_HOME_DIR" | grep -vF "${DATA_DIR}" >> "${DATA_DIR}/${scan_file}" 2> /dev/null
    grep -RlF '@eval($_POST[' "$WEBSITE_HOME_DIR" | grep -vF "${DATA_DIR}" >> "${DATA_DIR}/${scan_file}" 2> /dev/null

    if [ `cat "${DATA_DIR}/${scan_file}" | wc -l` -gt 0 ]
    then
        # podejrzane pliki
        echo -e "\n--- Podejrzane pliki ---"          >> "$ALERT_FILE"
        cat "${DATA_DIR}/${scan_file}" | sort | uniq  >> "$ALERT_FILE"
    fi
}


function check_all_files()
{
    local checksum_changes="sum_changes.log"
    local checksum_file="sum.log"
    local checksum_file_new="sum_new.log"
    local checksum_file_tmp="sum_tmp.log"

    find "$WEBSITE_HOME_DIR" \( -name "*.php" -o -name "*.html" -o -name "*.js" -o -name ".htaccess" \) -printf '%P\n' 2> /dev/null | while IFS= read line
    do
        "$SHA256SUM_BIN" "${WEBSITE_HOME_DIR}/${line}" >> "${DATA_DIR}/${checksum_file_tmp}"
    done

    cat "${DATA_DIR}/${checksum_file_tmp}" | sort > "${DATA_DIR}/${checksum_file_new}"
    rm -f "${DATA_DIR}/${checksum_file_tmp}"

    if [ ! -f "${DATA_DIR}/${checksum_file}" ]
    then
        # pierwsze uruchomienie
        mv -f "${DATA_DIR}/${checksum_file_new}" "${DATA_DIR}/${checksum_file}"
        local num_lines=`cat "${DATA_DIR}/${checksum_file}" | wc -l`
        echo -e "\n --- Zmienione pliki ---- $num_lines" >> "$ALERT_FILE"
    else
        diff --unchanged-line-format= --old-line-format= --new-line-format='%L' "${DATA_DIR}/${checksum_file}" "${DATA_DIR}/${checksum_file_new}" > "${DATA_DIR}/${checksum_changes}"
        local num_lines=`cat "${DATA_DIR}/${checksum_changes}" | wc -l`
        if [ "$num_lines" -gt 0 ] && [ "$num_lines" -lt 10 ]
        then
            echo -e "\n--- Zmienione pliki ---- $num_lines" >> "$ALERT_FILE"
            cat "${DATA_DIR}/${checksum_changes}" | "$AWK_BIN" '{print $2}' >> "$ALERT_FILE"
        fi
    fi
    mv -f "${DATA_DIR}/${checksum_file_new}" "${DATA_DIR}/${checksum_file}"
}

# ------------------------------

function prepare()
{
    rm -f "$ALERT_FILE"
    #rm -f "$ERROR_FILE"
    mkdir -p "$DATA_DIR"
    cur_date=`date '+%Y-%m-%d %H:%M:%S'`
    echo "---------- $cur_date ----------" >> "${ERROR_FILE}"
}

function basic_information()
{
    local wp_version_command="$PHP_CLI $WP_CLI core version $WP_CLI_OPTIONS"
    local wp_siteurl_command="$PHP_CLI $WP_CLI option get siteurl $WP_CLI_OPTIONS"

    local wp_version=`eval "$wp_version_command"`
    local wp_siteurl=`eval "$wp_siteurl_command"`

    if [ -f "${ALERT_FILE}" ]
    then
        echo >> "$ALERT_FILE"
        echo "Wersja WordPressa: $wp_version" >> "${ALERT_FILE}"
        echo "URL strony: $wp_siteurl" >> "${ALERT_FILE}"
    fi
}



### ---------------------------------------------------------------------------
###                               MAIN
### ---------------------------------------------------------------------------

prepare

# comment line to disable
# ---------------------------
check_plugin_update
check_theme_update
check_core_update
check_core_verify_checksums
check_user_modifications

# --------------------
# wersja podstawowa
check_file_htaccess
check_file_wp_config
check_file_index
check_all_files

# wersja rozszerzona
simple_scan
# --------------------

basic_information
# ---------------------------

if [ -f "${ALERT_FILE}" ] && [ `cat "${ALERT_FILE}" | wc -l` -gt 1 ]
then
    echo "Czas wykonywania skryptu: $SECONDS sekund" >> "${ALERT_FILE}"
    cat "${ALERT_FILE}" | /usr/bin/mail -s "Raport wp-guardian" "$ALERT_EMAIL"
fi
