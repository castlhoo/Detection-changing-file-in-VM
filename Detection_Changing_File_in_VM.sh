#!/bin/bash

# JAR 파일 경로 설정
JAR_FILE="./SpringApp-0.0.1-SNAPSHOT.jar"

# 실행할 .sh 파일 경로 설정
SH_FILE="./autorunning.sh"

# COOLDOWN 중복 실행 방지 대기 시간 (예: 10초)
COOLDOWN=10
LAST_RUN=0

# 파일 수정 감지 및 .sh 파일 실행
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    CURRENT_TIME=$(date +%s)

    # 마지막 실행 후 지정된 시간이 지났는지 확인
    if (( CURRENT_TIME - LAST_RUN > COOLDOWN )); then
        echo "$(date): $filename 파일이 수정되었습니다."  # 수정 시간 로그 추가
        
        # .sh 파일 실행
        bash "$SH_FILE"
        
        # 마지막 실행 시간 업데이트
        LAST_RUN=$CURRENT_TIME
        
        # 파일을 원격 서버로 전송
        scp "/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar" "username@10.0.2.19:/home/username/appjardir2"
        if [ $? -eq 0 ]; then
            echo "$(date): $filename 파일이 성공적으로 $REMOTE_SERVER 서버로 전송되었습니다."
        else
            echo "$(date): $filename 파일 전송에 실패했습니다."
        fi
    else
        echo "$(date): 쿨다운 기간 중입니다. 실행하지 않음."
    fi
done
