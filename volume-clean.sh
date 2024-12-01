#!/bin/bash

unused_volumes=$(docker volume ls --filter dangling=true -q)

if [ -z "$unused_volumes" ]; then
  echo "사용되지 않는 볼륨이 없습니다."
else
  echo "사용되지 않는 볼륨 목록:"
  echo "$unused_volumes"

  read -p "이 볼륨들을 삭제하시겠습니까? (y/n): " confirm
  if [ "$confirm" == "y" ]; then
    docker volume rm $unused_volumes
    echo "사용되지 않는 볼륨이 삭제되었습니다."
  else
    echo "삭제 작업이 취소되었습니다."
  fi
fi
