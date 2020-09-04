#!/bin/bash -e
# Bash script to make git semantic version tagging a brease
# Call with -h/--help to see usage details

# Replaces 'unknown' terMINORal with 'xterm' for 'tput' colors to work in the pipelines
TERM=${TERM/unknown/xterm}
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
pink=`tput setaf 5`
blue=`tput setaf 6`
orange=`tput bold`
reset=`tput sgr0`

# Helper function to capture confirmation prompts
function confirm_msg() {
  if [[ $AUTO_YES = "true" ]]; then
    return 0
  fi
  # Call with a prompt string or use a default
  read -r -p "${1:-Are you sure? [y/N]} " response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# Helper function to tag the latest commit in the branch and push to the repository
function tag_now() {
  TAG=${1}
  printf "*Adding git tag ${green}$TAG${reset} ...\n"
  git tag -a $TAG -m $TAG
  git push --tags
}

# Helper function to increment the given SEMVER_TAG (ex: v1.3.16) based on the INCREMENT_TYPE (major/minor/patch)
function semver_increment() {
  SEMVER_TAG=${1}
  INCREMENT_TYPE=${2:patch}
  SEMVER_TAG="${SEMVER_TAG/v/}"
  IFS='.' read -a vers <<< "$SEMVER_TAG"

  MAJOR=${vers[0]}
  MINOR=${vers[1]}
  PATCH=${vers[2]}
  re='^[0-9]+$'
  if ! [[ "$MAJOR$MINOR$PATCH" =~ $re ]] ; then
    printf "${red}ERROR: ${orange}$SEMVER_TAG${reset} ${red}can only contain dots and numbers for this script to work!\n${reset}" >&2
    exit 1
  fi
  case $INCREMENT_TYPE in
    "major")
      ((MAJOR+=1))
      MINOR=0
      PATCH=0
      ;;
    "minor")
      ((MINOR+=1))
      PATCH=0
      ;;
    "patch")
      ((PATCH+=1))
      ;;
  esac
  # Standard for git semver version tags to be prefixed with v
  printf "v$MAJOR.$MINOR.$PATCH"
}

# Helper function to print the script usage block
function print_usage() {
  cat <<EOM
Usage: $(basename $0) [-MmPyh]

SEMVER 2 options, given a version number ${red}major${reset}.${yellow}minor${reset}.${green}patch${reset}, increment the:
  -M, ${red}--major${reset}     When you make incompatible API changes.
  -m, ${yellow}--minor${reset}     When you add functionality in a backwards compatible manner.
  -p, ${green}--patch${reset}     When you make backwards compatible bug fixes.

Other options:
  -y, --yes       Say yes to the tag add prompts.
  -h, --help      Print this usage message.
EOM
}

# Increment by default the patch, unless instructed otherwise by the options
BUMP_INCREMENT="patch"
AUTO_YES="false"
for cmd in "$@"; do
  case $cmd in
    -M|--major)
      BUMP_INCREMENT="major"
      ;;
    -m|--minor)
      BUMP_INCREMENT="minor"
      ;;
    -p|--patch)
      BUMP_INCREMENT="patch"
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -y|--yes)
      AUTO_YES="true"
      ;;
  esac
done

LATEST_TAG=`git describe --tags $(git rev-list --tags --max-count=1) 2> /dev/null || true`

if [ -z $LATEST_TAG ] ; then
  FIRST_TAG="v0.0.1"
  confirm_msg "-No tag found in this git repository, add tag ${yellow}$FIRST_TAG ${reset}? [y/N]" && tag_now $FIRST_TAG
  exit 0
fi

printf "*Latest git tag found ${yellow}${LATEST_TAG}${reset}\n"

NEW_TAG=$(semver_increment $LATEST_TAG $BUMP_INCREMENT)

confirm_msg "-Tag the latest git commit with ${green}$NEW_TAG ${reset}? [y/N]" && tag_now $NEW_TAG BUMP_INCREMENT
