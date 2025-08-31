
#### firewall-cmd

```
firewall-cmd --state
firewall-cmd --get-active-zones


firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="8081" accept'
firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="5000" accept'
firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="6379" accept'
firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="6100" accept'
firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="udp" port="6100" accept'
firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="29092" accept'

firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" port protocol="tcp" port="8081" drop'

firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="80" accept'

firewall-cmd --reload

firewall-cmd --list-rich-rules

firewall-cmd --permanent \
  --remove-rich-rule='rule family="ipv4" source address="172.28.200.2" port protocol="tcp" port="8081" accept'

firewall-cmd --permanent \
  --remove-rich-rule='rule family="ipv4" port protocol="tcp" port="8081" drop'

```

#### git reabse

```

git pull --rebase origin main
원격 저장소의 변경사항을 가져와 내 커밋을 그 위에 재적용합니다.

충돌(conflict)이 발생할 수도 있으니, 그때는 수동으로 해결 후 다음을 입력합니다:

git add <conflicted files>
git rebase --continue

git push origin main

git push -f origin main

git remote show origin

git clean -fd
git clean은 수정된 파일은 삭제하지 않습니다.

git restore --staged .     # stage 취소
git restore .              # 수정도 되돌림

git clean -fdn    # 실제 삭제하지 않고 리스트만 보여줌
git clean -fdx    # x: .gitignore도 무시하고 모두 삭제
```

#### docker images
ubi9 (Universal Base Image 9)

ubi9는 RedHat에서 제공하는 RHEL 9 기반의 범용 베이스 이미지(Universal Base Image)

특징
- RHEL과 동일한 패키지 품질
- 라이센스 없이 공개 배포 가능
- RHEL 기반 환경에서 실행되도록 설계됨


Debian 버전
- stretch 9 (구버전)
- buster  10  (구버전)
- bullseye  11  (이전 안정버전)
- bookworm  12  stable 버전
- trixie  13  (테스트 중, unstable/sid)

