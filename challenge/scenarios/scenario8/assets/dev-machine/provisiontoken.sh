#!/bin/bash
COUNT=1
SETUP_TOKEN_SUCCESS=0
while [[ $SETUP_TOKEN_SUCCESS -ne 1 ]]; do
  echo "start loop $COUNT"
  sleep 30
  echo "start command"
  sudo gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :sudo, :write_repository], name: 'Access token'); token.set_token('${set_token}'); token.save!"
  COMMAND_EXIT=$?
  if [[ $COMMAND_EXIT -eq 0 ]]; then
    echo "setup complete"
    SETUP_TOKEN_SUCCESS=1
  fi
  if [[ $COUNT -ge 10 ]]; then
    break
  else
    let COUNT++
  fi
done
