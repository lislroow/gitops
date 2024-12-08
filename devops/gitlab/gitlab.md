#### pipline

```yml
stages:
  - build
  - deploy

include:
  - local: "story-app/.gitlab-ci.yml"
  - local: "story-eureka/.gitlab-ci.yml"

build_story-app:
  extends: .build_story-app
  variables:
    DOCKER_REGISTRY: docker.mgkim.net:5000
    GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"
    MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"
  rules:
    - if: $CI_COMMIT_BRANCH !~ /^(develop|staging|prod|main)/
      when: never
    - changes:
        paths:
          - story-app/**/*

deploy_develop_story-app:
  extends: .deploy_story-app
  variables:
    PROFILE: "develop"
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      changes:
        paths:
          - story-app/**/*
  #only:
  #  changes:
  #    - story-app/**/*
  #  refs:
  #    - /develop$/
```


```yml
.build_story-app:
  stage: build
  tags:
    - java8
  cache:
    - key: "CI_PROJECT_NAME-gradle-cache"
      paths:
        - "CI_PROJECT_DIR/.gradle/cache"
        - "CI_PROJECT_DIR/.gradle/wrapper"
    - key: "CI_PROJECT_NAME-maven-cache"
      paths:
        - "$CI_PROJECT_DIR/.m2/repository"
  variables:
    APP_NAME: "story-app"
  script:
    - echo $PWD
    - java -version
    - ./mvnw "$MAVEN_OPTS" -f $APP_NAME/pom.xml package
    #- ./gradlew :$APP_NAME:build --parallel --build-cache
    - docker build --build-arg APP_NAME=$APP_NAME -f $APP_NAME/Dockerfile -t $DOCKER_REGISTRY/$APP_NAME:$CI_PIPELINE_ID.$CI_COMMIT_SHORT_SHA .
    - docker push $DOCKER_REGISTRY/$APP_NAME:$CI_PIPELINE_ID.$CI_COMMIT_SHORT_SHA
    - docker rmi $DOCKER_REGISTRY/$APP_NAME:$CI_PIPELINE_ID.$CI_COMMIT_SHORT_SHA

.deploy_story-app:
  stage: deploy
  tags:
    - deploy
  script:
    - echo "check packages ..."
    - echo "from branch $CI_COMMIT_BRANCH"
    - echo "deploy $PROFILE"
```

#### root, 관리자 계정 초기 패스워드

```
# /etc/gitlab/initial_root_password

docker exec -it gitlab cat /etc/gitlab/initial_root_password
```