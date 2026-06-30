ai() {
  claude --settings '{"ultracode":true}' --dangerously-skip-permissions "$@"
}
