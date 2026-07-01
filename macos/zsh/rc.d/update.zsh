update() {
  brew update && brew upgrade && brew cleanup
  zinit update --all
}
