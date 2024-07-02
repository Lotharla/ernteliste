#!/bin/bash
export CHROME_EXECUTABLE=$(which chromium)
DIR=$(realpath $(dirname "$0"))
srvr=(dart run "--define=APP_HOME=$(printf -v home %q "$DIR")" bin/server.dart)
function dbfile() {
    local db=$("${srvr[@]}" --database)
    echo ${db#* }
}
cd "$DIR/server"
function adb_tools() {
    package_name='com.example.ernteliste'
    file_name='ernteliste.db'
    device_file_name="databases/$file_name"
    read -p "local file name : " -rei "$dbfile" local_file_name
    PS3='Task? ' ; select task in 'devices' 'shell' 'push' 'pull' ; do
        case "$task" in
        (devices)
            adb devices ;;
        (shell)
            adb shell ;;
        (push)
            adb -d shell chmod 777 /data/local/tmp/
            adb -d push "$local_file_name" /data/local/tmp/
            adb -d shell "run-as $package_name chmod 777 \"$device_file_name\""
            adb -d shell "run-as $package_name cp /data/local/tmp/$file_name \"$device_file_name\""
            adb -d shell "run-as $package_name chmod 600 \"$device_file_name\""
            ;;
        (pull)
            adb -d shell chmod 777 /data/local/tmp/
            adb -d shell "run-as $package_name chmod 777 \"$device_file_name\""
            adb -d shell "run-as $package_name cp \"$device_file_name\" /data/local/tmp/$file_name"
            adb -d shell "run-as $package_name chmod 600 \"$device_file_name\""
            adb -d pull /data/local/tmp/$file_name "$local_file_name"
            ;;
        esac
        break
    done
}
function database_tools() {
    local dbfile="$(dbfile)"
    echo "$dbfile"
    PS3='Task? ' ; select task in 'reset' 'sqlite' 'adb' ; do
        case "$task" in
        (reset)
            "${srvr[@]}" --reset ;;
        (sqlite)
            rlwrap sqlite3 "$dbfile" ;;
        (adb)
            adb_tools ;;
        esac
        break
    done
}
PS3='Task? ' ; select task in 'web app' 'server only' 'database' ; do
    case "$task" in
    (web*)
        "${srvr[@]}" --webapp ;;
    (server*)
        "${srvr[@]}";;
    (database*)
        database_tools ;;
    esac
    break
done
