#!/bin/bash
export CHROME_EXECUTABLE=$(which chromium)
DIR=$(realpath $(dirname "$0"))
srv=(dart run "--define=APP_HOME=$(printf -v home %q "$DIR")" bin/server.dart)
cd "$DIR/server"
function android_handling() {
    select task in 'devices' 'shell' 'push' 'pull' ; do
        case "$task" in
        (devices)
            adb devices ;;
        (shell)
            adb shell ;;
        esac
        break
    done
}
function database_handling() {
    select task in 'reset' 'sqlite' 'android' ; do
        case "$task" in
        (reset)
            "${srv[@]}" --reset ;;
        (sqlite)
            db=$("${srv[@]}" --database)
            db=${db#* }
            rlwrap sqlite3 ${db} ;;
        (android)
            android_handling ;;
        esac
        break
    done
}
select task in 'web app' 'server only' 'database' ; do
    case "$task" in
    (web*)
        "${srv[@]}" --webapp ;;
    (server*)
        "${srv[@]}";;
    (database*)
        database_handling ;;
    esac
    break
done
