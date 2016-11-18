#!/bin/bash

is_valid_sha() {
	case $1 in
		( *[!0-9A-Fa-f]* | "" ) return 1 ;;
        ( * )
		case ${#1} in
			( 32 | 40 ) return 0 ;;
			( * )       return 1 ;;
		esac
	esac
}

clear
echo "This is script which will guide you through updating any submodule"
echo "please wait - updating submodules info ... "
git submodule sync --recursive
git submodule update --init --recursive

echo "updated !"

cd submodules
options=($(ls -1d *))
cd -

echo ""
echo "****************************************"
echo "Please choose the submodule"

PS3='Which submodule you want to update: '
select submodule in "${options[@]}"
do
    break
done


if [ "$submodule" ]; then
    echo "checking the submodule -> $submodule"
    version=`git submodule status | grep submodules/$submodule | egrep -o  "([0-9a-z]{40})"`

    cd submodules/$submodule
    if ! git diff-index --quiet HEAD --; then
      echo ""
      echo "There are some local modifications in your submodule, please commit them before continuing"
      echo ""
      echo "operation aborted"
      echo ""
      exit 0
    fi

else
    echo "You haven't choose any submodule"
    exit 0
fi

echo "Please decide either you want to provide SHA manually or you want to choose from log"
PS3='Choose option: '
choices=("Log" "Manually")
select choice in ${choices[@]}
do
    echo $choice
    break
done

if [ "$choice" = "Log" ]; then
    echo "current SHA is : >>> $version <<< "
    echo "please wait ..."
    git fetch
    IFS=$'\n';

    logs2=`git ls-remote --heads && git log origin --pretty=format:'%H "%s"' -n 20`
    logs=()
    for log2 in ${logs2[@]}
    do
        currentSha=${log2:0:40}
        if [ "$currentSha" = "$version" ]; then
            log2=">> $log2"
        else
            log2="   $log2"
        fi
        logs+=($log2)
    done

    PS3='Please choose the SHA: '
    select log in ${logs[@]}
    do
        sha=${log:3:40}
        log_message=${log:44:500}
        break
    done

else
    echo "Please provide the SHA and press ENTER"
    read sha
fi

if is_valid_sha $sha ; then
    echo "YOU ARE ABOUT TU UPDATE MAIN CODE"
    echo "------------------------------"
    echo "You have choosen:"
    echo "submodule:   $submodule"
    echo "SHA:         $sha"
    echo "message:     $log_message"
    echo "------------------------------"
    if [ "$version" == "$sha" ]; then
        echo ""
        echo "Your current version is the same like chosen SHA"
        echo "You don't need to update to that"
        echo "aborting ...."
        exit 0
    fi

    PS3='Continue ?'
    options=("NO" "NO" "NO" "NO" "YES")
    select option in ${options[@]}
    do
        echo $option
        break
    done

    if [ "$option" = "YES" ]; then
        git checkout -q $sha
        cd -
        git commit -am"submodule($submodule): Updated to revision: $sha"
        echo "submodule($submodule): Updated to revision $sha"
        echo "SUCCESS >>>> "
        echo "Now please:"
        echo "1. 'grunt shaka' - to build the version of shaka"
        echo "2. 'git push .... ' - push all to github - submodule update and new shaka version"
    else
        echo "ABORTING"
    fi

else
    echo "Choosen SHA '($sha)' is NOT valid"
fi
