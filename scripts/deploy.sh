#!/bin/bash
set -e

if [[ -z "${DEPLOY_REMOTE_HOST:-}" ]]; then
  echo "❌ Error: DEPLOY_REMOTE_HOST environment variable is not set."
  exit 1
fi

if [[ -z "${DEPLOY_LOCAL_SOURCE:-}" ]]; then
  echo "❌ Error: DEPLOY_LOCAL_SOURCE environment variable is not set."
  exit 1
fi

if [[ -z "${DEPLOY_TARGET_DIR:-}" ]]; then
  echo "❌ Error: DEPLOY_TARGET_DIR environment variable is not set."
  exit 1
fi

REMOTE_HOST=${DEPLOY_REMOTE_HOST}
LOCAL_SOURCE=${DEPLOY_LOCAL_SOURCE}
TARGET_DIR=${DEPLOY_TARGET_DIR}
KEEP_RELEASES=${DEPLOY_KEEP_RELEASES:-3}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting deployment to ${REMOTE_HOST}${NC}"

TIMESTAMP=$(date +"%Y%m%d%H%M%SZ")
RELEASE_PATH="${TARGET_DIR}/releases/${TIMESTAMP}"

echo -e "${GREEN}Creating directory structure...${NC}"
ssh "${REMOTE_HOST}" "mkdir -p ${TARGET_DIR}/{releases,shared}"
ssh "${REMOTE_HOST}" "mkdir -p ${RELEASE_PATH}/public"

echo -e "${GREEN}Uploading files...${NC}"
rsync -avz --delete \
  "${LOCAL_SOURCE}/" \
  "${REMOTE_HOST}:${RELEASE_PATH}/public"

echo -e "${GREEN}Updating current symlink...${NC}"
ssh "${REMOTE_HOST}" "ln -nfs ${RELEASE_PATH} ${TARGET_DIR}/current"

echo -e "${GREEN}Cleaning up old releases...${NC}"
ssh "${REMOTE_HOST}" "cd ${TARGET_DIR}/releases && ls -t | tail -n +$((KEEP_RELEASES + 1)) | xargs -r rm -rf"

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "Release: ${TIMESTAMP}"
echo -e "Path: ${RELEASE_PATH}"
