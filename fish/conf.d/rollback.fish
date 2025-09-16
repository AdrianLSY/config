function rollback --description 'Rollback to the latest Snapper single snapshot and delete it afterward'
    if not command -qs snapper
        echo "rollback: snapper not found."
        return 1
    end

    set -l snapper_args
    if sudo snapper --config root list >/dev/null 2>&1
        set snapper_args --config root
        echo "rollback: using snapper config 'root'."
    else
        echo "rollback: no Snapper 'root' config found. Cannot rollback."
        return 1
    end

    echo "rollback: locating latest 'single' snapshot id..."
    set -l last_id (sudo snapper $snapper_args list --type single --columns number | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tail -n 1 | tr -d '[:space:]')
    if test -z "$last_id"
        echo "rollback: no 'single' snapshots found."
        return 1
    end

    echo "rollback: rolling back to snapshot ID $last_id ..."
    if not sudo snapper $snapper_args rollback $last_id
        echo "rollback: rollback failed."
        return 1
    end

    echo "rollback: deleting snapshot ID $last_id ..."
    if not sudo snapper $snapper_args delete $last_id
        echo "rollback: failed to delete snapshot ID $last_id (please remove manually)."
        return 1
    end

    echo "rollback: complete. Reboot to switch to the rolled-back system state."
end
