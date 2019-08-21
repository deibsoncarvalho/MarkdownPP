#!/bin/bash

set -eu

BUILD_DIR=~/out
HTML_DIR=/home/www/doc

declare -A BRANCH_PUBDIR=(
    # px3
    ["core-px3-sej"]="Core-PX3-SEJ"

    ["core-px30-jd4"]="Core-PX30-JD4"

    # 3128
    ["firefly-rk3128"]="Firefly-RK3128"
    ["aio-3128c"]="AIO-3128C"
    ["core-3128j"]="Core-3128J"

    # 3288
    ["firefly-rk3288"]="Firefly-RK3288"
    ["aio-3288c"]="AIO-3288C"
    ["aio-3288j"]="AIO-3288J"
    ["core-3288j"]="Core-3288J"
    ["ec-a3288c"]="EC-A3288C"
    ["ipc-m10r800-a3288c"]="IPC-M10R800-A3288C"

    ["eca3288c"]="SKIP"

    # 3328
    ["roc-rk3328-cc"]="ROC-RK3328-CC"
    ["roc-rk3328-pc"]="ROC-RK3328-PC"
    ["core-3328-jd4"]="Core-3328-JD4"

    # 3399
    ["firefly-rk3399"]="Firefly-RK3399"
    ["roc-rk3399-pc"]="ROC-RK3399-PC"
    ["aio-3399c"]="AIO-3399C"
    ["aio-3399j"]="AIO-3399J"
    ["core-3399-jd4"]="Core-3399-JD4"
    ["core-3399j"]="Core-3399J"
    ["ec-a3399c"]="EC-A3399C"
    ["ipc-m10r800-a3399c"]="IPC-M10R800-A3399C"
	["jinja2/rk3399"]="LIST:Firefly-RK3399,AIO-3399J,AIO-3399C,AIO-3399PRO-JD4"

    ["aio-3399jd4"]="SKIP"
    ["rk3399"]="SKIP"

    # 3399pro
    ["core-3399pro-jd4"]="Core-3399pro-JD4"

    # Face
    ["face-rk3399"]="Face-RK3399"
    ["face-x1"]="Face-X1"
    ["face-sdk-OpenAIlab"]="Face-SDK-OpenAIlab"

    # Misc
    ["NCC-S1"]="NCCS1"
    ["ai-develop"]="AI-Develop"
    ["dm-m10r800"]="DM-M10R800"
    ["firefly-api"]="FireflyApi"

    ["master"]="SKIP"
    ["HEAD"]="SKIP"
    ["test"]="TestDoc"
    ["build"]="SKIP_DEPLOY"
)

die() {
    echo "ERROR: $@"
    exit 1
} >&2

deploy_sub() {
    SUB="$1"
    if [ -f "${BUILD}${SUB}/conf.py" ]; then
	DEST="${HTML_DIR}${SUB}/${PUBDIR}"
	[ -d "$DEST" ] || mkdir -p "$DEST" || die "Cannot create $DEST"
	echo "Deploy to ${DEST}..."
	(
	    PS1="$$"
	    cd "${BUILD}${SUB}" \
		&& rm -rf _build \
		&& source ~/sphinx-markdown/bin/activate \
		&& make html \
		&& rsync -av _build/html/ $DEST/
	) || die "Deploy failed"
    fi
}

deploy() {
    echo
    echo "**** BUILD DATE $(date)"
    echo

    # Check branch

    REF="${1:-}"
    [[ -z "$REF" ]] && die "No REF specified."

    BRANCH=${REF##refs/heads/}
    [[ "$BRANCH" == "refs"* ]] && "$REF not in refs/heads namespace."

    PUBDIR="${BRANCH_PUBDIR[$BRANCH]:-}"
    if [[ -z "$PUBDIR" ]]; then
        die "Error: branch '$BRANCH' has no PUBDIR registered!"
    elif [[ "$PUBDIR" == "SKIP" ]]; then
        echo "Skip branch '$branch' according to configuration."

##在这里添加判断

        return 0
    fi
    if ! git rev-parse $REF &>/dev/null; then
        echo "$REF may be deleted?"
        return 0
    fi

    # Checkout source

    BUILD=${BUILD_DIR}/${BRANCH}
    [[ -d $BUILD ]] && rm -rf $BUILD
    mkdir -p $BUILD
    echo "Checkout branch '$BRANCH' to ${BUILD}..."
    git archive $REF | tar x -C "$BUILD"
    git rev-parse $REF > $BUILD/.revision

    # Build and sync
    if [[ "$PUBDIR" == "SKIP_DEPLOY" ]]; then
        echo "Skip build."
    else
        FOLDERS=("" "/en" "/zh_CN")
        for sub in "${FOLDERS[@]}"; do
	    deploy_sub "$sub"
        done
    fi
    :
}

deploy "$@" 2>&1 | tee -a $BUILD_DIR/buildoc.log
